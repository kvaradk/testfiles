import json
import subprocess
import random
import logging
import traceback

# Set up logging for better debugging
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')


def get_hostname(compartment_id, region):
    logging.info('running command to get hostname..')
    command = (
        f"oci compute instance list " 
        f"--compartment-id {compartment_id} --region {region} "
        "--output json"
    )
    # Print command for debugging
    logging.debug(f"Executing command: {command}")
    try:
        res = subprocess.run(command, shell=True, capture_output=True, check=True, text=True)
        instances = json.loads(res.stdout)
        displayNames = []
        for instance in instances['data']:
            if "display-name" in instance and instance["display-name"]:
                displayNames.append(instance["display-name"])

        return displayNames
        
    
    except subprocess.CalledProcessError as e:
        logging.error(f"Error fetching instance list: {e}")
        logging.error(f"OCI CLI Output: {e.output.decode() if e.output else 'No output'}")
        logging.error(f"OCI CLI Error: {e.stderr.decode() if e.stderr else 'No error'}")
        logging.debug(f"Error traceback: {traceback.format_exc()}")
        return []
    except json.JSONDecodeError as e:
        logging.error(f"Error parsing JSON response: {e}")
        logging.debug(f"Error traceback: {traceback.format_exc()}")
        return []
    except Exception as e:
        logging.error(f"Unexpected error occurred in get_hostname: {e}")
        logging.debug(f"Error traceback: {traceback.format_exc()}")
        return []
    
def extractData():
# data['region'][3:-2] gets the appropriate region to map values to

# because "service" is not in payload, we'll be hard-coding the service to mid tier for now

    try:
        with open('config.json', "r") as file:
            data = json.load(file)
        regionName, tenancyName, appShortName, Prov_Env_typeName, os_typeName, serviceName = [
            data['region'][3:-2].lower(), \
            data['tenancy_name'].lower(), data['app_short_name'], \
            data['app_provisioning_env'].lower(), data['operating_system'].lower(), "midtier"
        ]
        if "linux" in os_typeName.lower():
            os_typeName = "linux"
        
        # print(regionName, tenancyName, appShortName, Prov_Env_typeName, os_typeName, serviceName)
        extractedVals = {"region": regionName, "tenancy_name": tenancyName, "app_short_name": appShortName, "app_provisioning_env": Prov_Env_typeName, "operating_system": os_typeName, "service": serviceName}
        # print(extractedVals)

        return extractedVals

    except FileNotFoundError as e:
        logging.error(f"Config file not found: {e}")
        logging.debug(f"Error traceback: {traceback.format_exc()}")
        return {}
    except json.JSONDecodeError as e:
        logging.error(f"Error parsing JSON from config file: {e}")
        logging.debug(f"Error traceback: {traceback.format_exc()}")
        return {}
    except Exception as e:
        logging.error(f"Unexpected error occurred in extractData: {e}")
        logging.debug(f"Error traceback: {traceback.format_exc()}")
        return {}

def generateHostName(hostNameValues):
    try:
        with open('enum.json', "r") as file:
            enumMap = json.load(file)
        hostNameRegion, hostNameTenancy, hostNameAppShortName, hostNameProvEnv, hostNameOsType, hostNameService = "", "", hostNameValues['app_short_name'], "", "", ""

        for key, val in hostNameValues.items():
            if key in enumMap:
                # print(key, val)
                if key == "region":
                    hostNameRegion = enumMap[key][val]
                elif key == "tenancy_name":
                    hostNameTenancy = enumMap[key][val]
                elif key == "app_provisioning_env":
                    hostNameProvEnv = enumMap[key][val]
                elif key == "operating_system":
                    hostNameOsType = enumMap[key][val]
                elif key == "service":
                    hostNameService = enumMap[key][val]
            
        # print(hostNameRegion, hostNameTenancy, hostNameAppShortName, hostNameProvEnv, hostNameOsType, hostNameService)
        if hostNameOsType == "WIN":
            hostName = hostNameRegion[:3] + hostNameAppShortName[:4] + hostNameProvEnv + "W"+ hostNameService[:2]
        else:
            hostName = hostNameRegion + hostNameTenancy + hostNameAppShortName + hostNameProvEnv + hostNameService[:2]
        
        return hostName
    except FileNotFoundError as e:
        logging.error(f"file for mapping values not found:  {e}")
        logging.debug()
        return ""
    except json.JSONDecodeError as e:
        logging.error(f"Error parsing JSON from enum file: {e}")
        logging.debug(f"Error traceback: {traceback.format_exc()}")
        return ""
    except KeyError as e:
        logging.error(f"Key error while generating hostname: {e}")
        logging.debug(f"Error traceback: {traceback.format_exc()}")
        return ""



def main():
    logging.info('Starting process of generating hostname..')
    try:
        dataForMapping = extractData()
        logging.info(f"extracted OCI values... {dataForMapping}")
        generatedName = generateHostName(dataForMapping)
        generatedName = generatedName.lower()
        logging.info(f"generated name for current OCI CLI Profile values: {generatedName}")

        # oci_config_file = "/Users/fawwahme/.oci/config"
        # with open(oci_config_file, "r") as file:
        #     content = file.read()

        with open('config.json', "r") as file:
            data = json.load(file)
        tenancy_name, compartment_id, region =  data['tenancy_name'], data['compartment_id'], data['region']
        hostnames = get_hostname(compartment_id, region)
        # check if number already exists in current compute Names. if so, continue within while loop until unique number is found
        i = 0
        uniqueNumber = 0
        foundDuplicate = False

        while i < 100 and not foundDuplicate:
            uniqueNumber = random.randint(1, 999)
            formattedNumber = str("{:03d}".format(uniqueNumber))
            foundDuplicate = False
            for name in hostnames:
                # print(name)
                if formattedNumber in name:
                    logging.info(f"{formattedNumber} already exists...creating new number"  )
                    break
                else:
                    logging.info("unique number found...")
                    foundDuplicate = True
                    break
            i += 1
        if i == 100:
            logging.error("Unable to find unique number for hostname after 100 attempts")
            return
        computeName = generatedName + formattedNumber
        addedNames = {'hostname_label': computeName, 'display_name': computeName}
        data.update(addedNames)
        with open('config.json', "w") as jsonfile:
            json.dump(data, jsonfile)
        logging.info(f"Generated hostname: {computeName}") 
        logging.info(f"updated config.json: {data}")
        print(computeName)
        return computeName
    except Exception as e:
        logging.critical(f"Unexpected error occured in main: {e}")
        logging.debug(f"Error traceback: {traceback.format_exc()}")

main()
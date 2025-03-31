import requests
import json

def nexus_search_latest(nexus_url, repository, group_id, artifact_id, packaging="jar"):
    search_url = f"{nexus_url}/{repository}/maven-metadata.xml/{group_id.replace('.', '/')}/{artifact_id}/maven-metadata.xml"
    try:
        response = requests.get(search_url)
        response.raise_for_status()
        xml_content = response.text
        latest_version_start = xml_content.find("<latest>") + len("<latest>")
        latest_version_end = xml_content.find("</latest>")
        if latest_version_start != -1 and latest_version_end != -1:
          latest_version = xml_content[latest_version_start:latest_version_end]
          print('latest_version: ', latest_version)
          return latest_version
        else:
          return None
    except requests.exceptions.RequestException as e:
        print(f"Error: {e}")
        return None
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        return None

# Example usage:
nexus_url = "http://your-nexus-url/repository"
repository = "maven-public" 
group_id = "com.google.guava"
artifact_id = "guava"
packaging = "jar"

latest_version = nexus_search_latest(nexus_url, repository, group_id, artifact_id, packaging)
print('2 latest_version: ', latest_version)

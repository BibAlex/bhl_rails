# Load the rails application
require File.expand_path('../application', __FILE__)

PROXY_ADDRESS = ""
PROXY_PORT = ""
PROXY_USERNAME = ""
PROXY_PASSWORD = ""

DAR_API_METADATA = 'http://api.dar.bibalex.org/DarAccessLayer/[BIBID]/getStream/descMetadata'
DAR_API_METADATA_BIBID_STRING = '[BIBID]'
DOWNLOAD_QUERY_SIZE = 100

DAR_API_THUMBNAIL = 'http://api.dar.bibalex.org/DarAccessLayer/DAF-Job:[JOBID]/Thumbnail'
DAR_API_THUMBNAIL_JOBID_STRING = '[JOBID]'

DAR_API_CONTENT = 'http://api.dar.bibalex.org/DarAccessLayer/DAF-Job:[JOBID]/Derivative/XML/Content';
DAR_API_CONTENT_JOBID_STRING = '[JOBID]'

LOCATION_API = "http://maps.googleapis.com/maps/api/geocode/xml?address=[LOC]&sensor=false"
LOCATION_API_LOC_STRING = "[LOC]"


# Initialize the rails application
Bhl::Application.initialize!


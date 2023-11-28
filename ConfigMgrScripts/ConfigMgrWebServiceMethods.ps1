# Connect to web service
$URI = "http://localhost/ConfigMgrWebService/ConfigMgr.asmx"
$Secret = "f1fb920f-c710-42ac-80ad-bf505512b66f"
$Web = New-WebServiceProxy -Uri $URI

# Invoke method
#$Web.RemoveCMDeviceByName("yoursecretkey", "username")#Save methods to variable$WebService = $Web
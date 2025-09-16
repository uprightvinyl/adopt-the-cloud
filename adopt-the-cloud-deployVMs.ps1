git clone https://github.com/uprightvinyl/adopt-the-cloud.git # Exlude this step if you have already cloned the repo
Invoke-WebRequest -outfile "install-opentofu.ps1" -uri "https://get.opentofu.org/install-opentofu.ps1"
.\install-opentofu.ps1 -installmethod standalone -skipVerify
cd adopt-the-cloud
tofu init
tofu apply -auto-approve

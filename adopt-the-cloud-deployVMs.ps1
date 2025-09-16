
Invoke-WebRequest -outfile "install-opentofu.ps1" -uri "https://get.opentofu.org/install-opentofu.ps1"
.\install-opentofu.ps1 -installmethod standalone -skipVerify
git clone https://github.com/uprightvinyl/adopt-the-cloud/adopt-the-cloud.git
cd adopt-the-cloud
tofu init
tofu apply -auto-approve

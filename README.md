# Flywheel Tech Assessment - AWS DevOps

## Task 1:
Provide terraform for a 3-tier network with Postgres rds, fault tolerance, and load balancing - please use multiple terraform state files.

Solution: Refer to this github path: (https://github.com/rudreshms/flywheel/tree/main/terraform-aws-3tier)
NOTE: I have ran and tested above TF code repo on my aws free tier account using below set of TF commands
terraform init
terraform validate
terraform fmt
terraform plan  --> terraform apply step is not performed as it incurs AWS cost.


## Task 2:
Provide a network diagram for the 3-tier network - please use strictly AWS.

Solution: https://github.com/rudreshms/flywheel/blob/main/Task2_Tier3_NetworkDiagram.drawio
<img width="895" height="749" alt="3Tier-Network-Architecture-AWSCloud" src="https://github.com/user-attachments/assets/7ecba587-ee7f-4573-92ed-cde975f08249" />


## Task 3:
Provide a helm chart for a Java application, and please specify scaling and resources.

Solution: Refer to this github link: (https://github.com/rudreshms/flywheel/tree/main/java_helm_charts)
NOTE: Ran the helm charts locally to test both lint and dry run feature, so that the same charts can be directly ran at cluster level.


## Task 4:
Provide a diagram of a standard git-flow merge to main with deployment. Please use git cli commands to demonstrate the process.

Solution: https://github.com/rudreshms/flywheel/blob/main/Standard_Gitflow_Process.drawio

<img width="514" height="469" alt="Standard_Gitflow_Process" src="https://github.com/user-attachments/assets/244910bd-94c9-4e54-9d73-34e27536efdf" />

<img width="1032" height="618" alt="Gitflow_Standard_Diagram" src="https://github.com/user-attachments/assets/f0bf09e3-1d2c-4dff-a75f-fa1b7918e6c8" />

Git CLI Commands for the above process as below:
git checkout feature
git push
git checkout main
git merge release
git push

Other git cli commands:
git rebase
git status
git log
git push -f origin

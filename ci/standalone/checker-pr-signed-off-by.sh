#!/usr/bin/env bash

## @file checker-pr-signed-off-by.sh
## @brief signedoff facility to check automatically whenever PR is submitted by contributor
## @param
##  arg1: PR number
##  arg2: Commit number (based on SHA)
##  arg3: Result value (success or failure) by checking "Signed-off-by: " rule
##         from commit message of PR
## @note
## First of all, We have to understand why we have to use "Signed-off-by" statement.
## We recommend that we have to require "Signed-off-by" line in git commit messages
## to author on our project as well as Linux community. "Is there a Signed-off-by" line?"
## is important because lawyers tell us we must have to it to cleanly maintain the license
## issues even though it has nothing to do with the code itself. So, the activity that we
## do append "Signed-off-by" line is helpful to developers as well as lawyers.
## 
## [FYI] How to give the developers zero cost:
## 
## $ vi ~/.gitconfig
##   [user]                                                                                                             
##           name = Gildong Hong
##           email = gildong.hong@samsung.com
## $ git commit -a -s  
## // -s (--signoff) means automated signed-off-by statement 
## 
##
## Lots of opensource communities have been using "Signed-off-by:" notation by default to handle the license issues that result from contributors.
## Refer to the below websites:
## * GPL violoation - http://gpl-violations.org/
## * Signed-off-by Process by LinuxFoundation - https://ltsi.linuxfoundation.org/developers/signed-process
## * Signed-off-by lines and the DCO - http://elinux.org/Legal_Issues#Signed-off-by_lines_and_the_DCO
## * Gerrit Code Review - Signed-off-by Lines - https://git.eclipse.org/r/Documentation/user-signedoffby.html
## 

# --------------------------- Pre-setting module ----------------------------------------------------------------------

source ./config/botenv.sh

# check if input argument is correct. 
if [[ $1 == "" || $2 == "" || $3 == "" ]]; then
    printf "[DEBUG] ERROR: Please, input correct arguments.\n"
    exit 1
fi

input_pr=$1
input_commit=$2
input_result=$3

# --------------------------- CI Trigger ----------------------------------------------------------------------
/usr/bin/curl -H "Content-Type: application/json" \
-H "Authorization: token "$TOKEN"  " \
--data '{"state":"pending","context":"CI/pr-signedoff","description":"Triggered. The commit number is '$input_commit'","target_url":"'${CISERVER}'"}' \
${GITHUB_WEBHOOK_API}/statuses/$input_commit


# --------------------------- Jenkins module: start -----------------------------------------------------

# Let's skip this step because the activity is already executed by webhook manager


 # --------------------------- Report module: submit check result to github.sec.samsung.net --------------
# execute a check result by checking a Signed-off-by string.
# https://developer.github.com/enterprise/2.10/v3/repos/statuses/#create-a-status

if [[ $input_result == "success" ]]; then
    # in case of success
    /usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data '{"state":"success","context":"CI/pr-signedoff","description":"Successfully signed off! This PR includes 'Signed-off-by:' string.","target_url":"'${REPOSITORY_WEB}/pull/${input_pr}/commits/${input_commit}'"}' \
     ${GITHUB_WEBHOOK_API}/statuses/$input_commit
elif [[ $input_result == "failure" ]]; then
    # in case of failure
    /usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data '{"state":"failure","context":"CI/pr-signedoff","description":"Oooops. No signoff found. This PR does not include 'Signed-off-by:' string. The lawyers tell us we must have it.","target_url":"'${REPOSITORY_WEB}/pull/${input_pr}/commits/${input_commit}'"}' \
     ${GITHUB_WEBHOOK_API}/statuses/$input_commit
    # inform contributors of meaning of Signed-off-by: statement
    message="To contributor, We have been using '**Signed-off-by:**' notation by default to handle the license issues, that result from contributors. Note that 'Is there a Signed-off-by line?' is important because lawyers tell us we must have to it **to cleanly maintain the license issues** such as GPL and LGPL even though it has nothing to do with the code itself."
    /usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data "{\"body\":\":octocat: **cibot**: $message \"}" \
     {GITHUB_WEBHOOK_API}/issues/$input_pr/comments
else
    # in case of CI error
    /usr/bin/curl -H "Content-Type: application/json" \
     -H "Authorization: token "$TOKEN"  " \
     --data '{"state":"error","context":"CI/pr-signedoff","description":"Oooops. It seems that CI bot includes bug(s). CI bot has to be fixed.","target_url":"'${REPOSITORY_WEB}/pull/${input_pr}/commits/${input_commit}'"}' \
     ${GITHUB_WEBHOOK_API}/statuses/$input_commit
fi
#!/bin/bash

# Make sure there is an associated pull request, then also make sure
# something changed in the ./web directory since we're only pushing
# up frontend changes
git diff origin/master --relative=web --exit-code
WEBCHANGES=$?
if [ -n "$CI_PULL_REQUESTS" ] && [ "$WEBCHANGES" -ne 0 ]; then
  PRNUM=`basename $CI_PULL_REQUESTS`

  set -e
  apt-get update
  apt-get -y -qq install jq awscli

  # check PR title and if it contains "[skip deploy]" then obey its wishes
  TITLE=$(curl -s -u "$GH_BOT_USER:$GH_BOT_PASSWORD" https://api.github.com/repos/18f/cms-hitech-apd/issues/$PRNUM | jq -r '.title')
  if [[ $TITLE = *"[skip deploy]"* ]]; then
    echo "Skipping deploy. All done."
    exit 0
  fi

  export API_URL=$STAGING_API_URL

  # Build the front-end
  cd web
  npm ci
  npm run build
  cd ..

  BUCKET="pr$PRNUM.hitech.eapd.cms.gov"
  BUCKET_URI="s3://pr$PRNUM.hitech.eapd.cms.gov"
  BUCKET_POLICY='{"Version":"2012-10-17","Statement":[{"Sid":"PublicReadGetObject","Effect":"Allow","Principal":"*","Action":"s3:GetObject","Resource":"arn:aws:s3:::'"$BUCKET"'/*"}]}'
  aws s3 mb $BUCKET_URI
  DEPLOYED_URL="http://$BUCKET.s3-website-us-east-1.amazonaws.com/"
  
  aws s3 sync web/dist $BUCKET_URI
  aws s3 website $BUCKET_URI --index-document index.html
  aws s3api put-bucket-policy --bucket $BUCKET --policy "$BUCKET_POLICY"

  # Update the comment on Github, if there's one already.  This way we'll know the bot updated the thing.
  COMMENTS=$(curl -s -u "$GH_BOT_USER:$GH_BOT_PASSWORD" https://api.github.com/repos/18f/cms-hitech-apd/issues/$PRNUM/comments | jq -c -r '.[] | {id:.id,user:.user.login}' | grep "$GH_BOT_USER" || true)
  if [ "$COMMENTS" ]; then
    ID=$(echo "$COMMENTS" | jq -c -r .id)
    # Use $ before the body to use ANSI encoding, which preserves the newlines.
    # Add the commit SHA so we know it deployed and when.
    curl -s -u "$GH_BOT_USER:$GH_BOT_PASSWORD" -d $'{"body":"See this pull request in action: '"$DEPLOYED_URL"'\n\n'"$CIRCLE_SHA1"'"}' -H "Content-Type: application/json" -X PATCH "https://api.github.com/repos/18f/cms-hitech-apd/issues/comments/$ID"
  else
    # Post a new message if one doesn't already exist.
    curl -s -u "$GH_BOT_USER:$GH_BOT_PASSWORD" -d '{"body":"See this pull request in action: '"$DEPLOYED_URL"'"}' -H "Content-Type: application/json" -X POST "https://api.github.com/repos/18f/cms-hitech-apd/issues/$PRNUM/comments"
  fi

elif [ "$WEBCHANGES" -eq 0 ]; then
  echo "No changes to /web"
else
  echo "Not a pull request"
fi
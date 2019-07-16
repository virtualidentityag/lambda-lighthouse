# Lighthouse in Lambda
Simple lambda function that takes a post request via AWS Api Gateway and runs 5 lighthouse tests and saves them to a s3 bucket.

## Why the node_modules in git?
Somehow it's tricky to install lighthouse and the right version of chrome for lambda in the same project, thats why everything is in version control.

## Lighthouse viewer
In order to view these JSON files this lighthouse instance could be used: `https://lighthouse-viewer.netlify.com`, it takes a hash and displays it's contents e.g. `https://lighthouse-viewer.netlify.com#https://myclouddomain/yourtestid.json`
Code is basically lighthouse viewer with the hash addition: `https://github.com/jurekbarth/lighthouse`

## Setup
1. Create a S3 Bucket or use an existing one and exchange `aws-lighouse` with `your-bucket-name`
2. You might need to install terraform, please use their instructions
3. Upload a zip file with the `node_modules` folder and `index.js` in it to your bucket
4. Exchange the `s3_key` in `main.tf` the the zip filename
5. Run `terraform init`
6. Run `terraform apply`

## Todo
- Serve JSON Files via Cloudfront
- Calculate an average of these five tests
- Let the developer set a budget
- Connect to Github with a Github App / Bot Account --> Needs to be a Github App if you want to be able to block a PR, based on the results
- Somehow create a client that starts the testing

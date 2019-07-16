# Lighthouse in Lambda
Simple lambda function that takes a post request via AWS Api Gateway and runs 5 lighthouse tests and saves them to a s3 bucket.

## Lighthouse viewer
In order to view these JSON files this lighthouse instance could be used: `https://lighthouse-viewer.netlify.com`, it takes a hash and displays it's contents e.g. `https://lighthouse-viewer.netlify.com#https://myclouddomain/yourtestid.json`
Code is basically lighthouse viewer with the hash addition: `https://github.com/jurekbarth/lighthouse`

## Todo
- Serve JSON Files via Cloudfront
- Calculate an average of these five tests
- Let the developer set a budget
- Connect to Github with a Github App / Bot Account --> Needs to be a Github App if you want to be able to block a PR, based on the results
- Somehow create a client that starts the testing

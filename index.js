const chromium = require('chrome-aws-lambda');
const lighthouse = require('lighthouse');
const { URL } = require('url');
const AWS = require('aws-sdk');
const {defaultSettings} = require('lighthouse/lighthouse-core/config/constants.js')
const config = require('lighthouse/lighthouse-core/config/default-config.js')

const secretApiKey = process.env.SECRET_API_KEY || 'pleaseChangeMeImInsecure';

// TODO make hash out of url and place it in front
const makeid = (length) => {
  let result           = '';
  const characters       = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  const charactersLength = characters.length;
  for ( var i = 0; i < length; i++ ) {
     result += characters.charAt(Math.floor(Math.random() * charactersLength));
  }
  return result;
}

const DEVTOOLS_RTT_ADJUSTMENT_FACTOR = 3.75;
const DEVTOOLS_THROUGHPUT_ADJUSTMENT_FACTOR = 0.9;

const customThrottling = {
  rttMs: 150,
  throughputKbps: 1.6 * 1024,
  requestLatencyMs: 150 * DEVTOOLS_RTT_ADJUSTMENT_FACTOR,
  downloadThroughputKbps: 1.6 * 1024 * DEVTOOLS_THROUGHPUT_ADJUSTMENT_FACTOR,
  uploadThroughputKbps: 750 * DEVTOOLS_THROUGHPUT_ADJUSTMENT_FACTOR,
  cpuSlowdownMultiplier: 1,
}

defaultSettings.throttling = customThrottling;

config.settings = defaultSettings;


const handleError = (error, callback) => {
  console.log(error.message);
  const response = {
    statusCode: 400,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Access-Control-Allow-Origin': '*'
    },
    body: JSON.stringify({ error: error.message })
  }
  callback(null, response);
}

const allowedKeys = ['secret', 'url'];

const checkForErrors = (body) => {
  const { secret, url } = body;
  for (const key in body) {
    if (!allowedKeys.includes(key)) {
      throw new Error(`key unknown: ${key}`)
    }
  }
  if (!(body.hasOwnProperty('secret'))) {
    throw new Error('secret missing');
  }
  if(secret !== secretApiKey) {
    throw new Error('secret wrong');
  }
  if (!(body.hasOwnProperty('url'))) {
    throw new Error('url missing');
  }
}

exports.handler = async (event, context, callback) => {
  const body = event.body;
  let reqBody = null;
  try {
    reqBody = JSON.parse(body);
  } catch (error) {
    console.log(error);
    return handleError(error, callback)
  }
  try {
    checkForErrors(reqBody);
  } catch (error) {
    console.log(error);
    return handleError(error, callback)
  }
  const testID = makeid(30);
  let browser = null;
  try {
    const s3 = new AWS.S3();
    browser = await chromium.puppeteer.launch({
      args: chromium.args,
      defaultViewport: chromium.defaultViewport,
      executablePath: await chromium.executablePath,
      headless: chromium.headless,
    });

    const tests = [1, 2, 3, 4, 5];

    for(let test of tests) {
      const lhr = await lighthouse(reqBody.url, {
        port: (new URL(browser.wsEndpoint())).port,
        output: 'json',
        logLevel: 'silent',
      }, config);


      await s3.putObject({
        Bucket: 'aws-lighthouse',
        Key: `${testID}_${test}.json`,
        Body: JSON.stringify(lhr),
        ContentType: "application/json"
      }).promise();
    }

  } catch (error) {
    return handleError(error, callback)
  } finally {
    if (browser !== null) {
      await browser.close();
    }
  }

  const response = {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Access-Control-Allow-Origin': '*'
    },
    body: JSON.stringify({ id: testID })
  }
  callback(null, response)
};

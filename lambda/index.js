const _ = require('lodash');

exports.handler = async(event , context) =>{
    console.log(event)
    console.log("Testing code from pipeline")
    const body = _.get(event , 'body' , '{}');
    console.log(body  , " bod.........................")
    return {
        statusCode : 200,
        message    : JSON.stringify("Hello world from lambda")
    } 
}
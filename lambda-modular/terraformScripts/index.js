exports.hello =(event , context) => {
    console.log("Welcome to Lambda")
    console.log("Event = ",event);
    console.log("Lambda end");
    console.log("Logs sent to cloudwatch")
    return {
        statusCode : 200,
        message     : JSON.stringify("Welcome to terraform lambda")
    }
}

exports.handler = async(event , context) =>{
    console.log(event)
    console.log("Testing code from pipeline")
    return {
        statusCode : 200,
        message    : JSON.stringify("Hello world from lambda")
    } 
}
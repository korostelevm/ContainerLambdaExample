
const lambdaHandler = async (event) => {
    console.log(JSON.stringify(event,null,2))
    return '5'
}

module.exports={
    lambdaHandler
}

if(module.parent) {
    console.log('required module')
} else {
    lambdaHandler({})
}

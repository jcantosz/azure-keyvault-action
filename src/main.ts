import * as core from '@actions/core';
import * as exec from '@actions/exec';
import { env } from 'process';
import stream = require('stream');

export const run = async () => {
    try {
        // if (process.env.RUNNER_OS != 'Linux') {
        //     core.setFailed('Please use Linux based OS as a runner.');
        //     return;
        // }

        // # Could also allow users to specify secret_type::secret_name so they could 
        // #  read secrets, certs and keys from a single step}
        let vaultName: string = core.getInput('vaultName', { required: true });
        // could use enums for this
        let objectType: string = core.getInput('objectType', { required: true });
        let objectKeys: Array<string> = core.getInput('objectKeys', { required: true }).split(',');
        let outputEnvs: boolean = core.getBooleanInput('outputEnvs', { required: false });
        let outputOutputs: boolean = core.getBooleanInput('outputOutputs', { required: false });


        for (let key of objectKeys){
            if(key){
                await exportSecret(objectType, vaultName, key, outputEnvs, outputOutputs);
            }
        }
    } catch (error) {
        core.error(error);
        core.setFailed(error.stderr);
        throw error;
    }
    finally {
        // clean up
    }
};

const cleanKey = async(key: string) => {
    //Secret names can only contain alphanumeric characters and dashes, but can start with number or dashes
    // Need to clean these so they can be valid env vars
    let cleaned = key.trim().replace(/[^a-z0-9]/gi, "_");
    return (cleaned.match(/^[0-9-]/g)) ? 'KEYVAULT_' + cleaned : cleaned;
}

const exportSecret = async (objectType: string, vaultName: string, key: string, outputEnvs: boolean, outputOutputs: boolean, continueOnError: boolean = false): Promise<void> => {
    try{
        let outputName = await cleanKey(key);
        let secret = await executeCommand(`az keyvault ${objectType} show --name "${key}" --vault-name "${vaultName}" --query "value"`, continueOnError);

        core.setSecret(secret);
        let outputType = "none";
        if (outputEnvs){
            core.exportVariable(outputName, secret);
            outputType = "env"
        }
        if (outputOutputs){
            core.setOutput(outputName, secret);
            outputType = (outputType != "none") ? outputType + " & outputs" : "outputs"
        }

        core.info(`Exported secret "${key}" as ${outputType} variable called "${outputName}"`)
    } catch(err) {
        core.setFailed(`Action failed at exportSecret with error ${err}`);
    }

}

class NullOutstreamStringWritable extends stream.Writable {

    constructor(options: any) {
        super(options);
    }

    _write(data: any, encoding: string, callback: Function): void {
        if (callback) {
            callback();
        }
    }
};

const executeCommand = async (command: string, continueOnError: boolean = false): Promise<string> => {
    let retVal: string;
    let errMsg: string;
    try{
        var execOptions: any = {
            outStream: new NullOutstreamStringWritable({ decodeStrings: false }),
            listeners: {
                stdout: (data: Buffer) => {
                    retVal += data.toString();
                },
                stderr: (data: Buffer) => {
                    errMsg += data.toString();
                }
            }
        };
            
        core.debug(`Executing ${command}`)
        let res = await exec.exec(command, [], execOptions);
        
    } catch(err) {
        let errorMessage = `Action failed at executeCommand with error ${err}`
        if (continueOnError){
            core.warning(errorMessage)
        }else{
            core.setFailed(errorMessage);
        }
    } finally {
        if (errMsg){
            core.setFailed(errMsg)
        }
    }
    return retVal;
}

run();
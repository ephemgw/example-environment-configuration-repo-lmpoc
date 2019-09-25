# Configuring Secrets

The following commands creates a secret encrypted by Kubeseal for the specified information, where '\<namespace\>' indicates which environment your secrets are created in:

##### Image Credentials
Secret encrypted by Kubeseal for image credentials:
```bash
./makeImageCreds.sh -namespace=<namespace> -dest=../releases/<namespace>/image-creds.yaml -password=<password>
```

##### License
This command creates a Secret encrypted by Kubeseal for license:
```bash
./makeLicense.sh -namespace=<namespace> -dest=../releases/<namespace>/gateway-license.yaml -license=<license.xml file>
```

##### Environment
Environment values are required for specific Gateway configurations to work.
Read more about environments: https://github.com/ca-api-gateway/gateway-developer-plugin/wiki/Applying-Environment.
Entities that include an _Environment_ section is supported. 

This command creates a Secret encrypted by Kubeseal for environment values:
```bash
./makeEnv.sh -namespace=<namespace> -dest=../releases/<namespace>/env.yaml -ext=<extension>
```

Since private keys files are required to be mounted onto the Gateway container and cannot be passed into an environment variable, it will be encrypted first as a Kubernetes secret and wrapped again with Sealed Secrets. In addition, this secret will be mounted onto the correct directory inside the container.

The command will take in an _extension_, which can be either json or yaml (depending on the type of exported Gateway environment values). It will then create an _env.yaml_ file that parses any entities files inside the _script/_ folder.

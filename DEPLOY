An azure template deployment must happen in a scope, which is one of:

   tenant
   subscription
   resourcegroup


The deployment scope is specified as a subcommand in the az cli:

  az deployment tenant --tenantname <tenant>
  az deployment sub --subscriptionname <sub>
  az deployment group` --groupname <group>

Also, a scope declaration may be required in the template file, on of:

  targetScope = 'tenant'
  targetScope = 'subscription'
 


Bicep loops and conditionals.

These can only be used if directly translatable to ARM template json support structures. They can't be used in the construction of array or object variables.


Bicep variables.

Scalar variables seem to be restricted to string/numerical values only. They can't be used to store references to azure resources.

Resource naming.

Each module constructs the name(s) of the resources it manages based on a prefix (which defaults to someting unique for the resource catergory), an optional infix part and a suffix that is provided by the caller and is used to distinguish names in a resource list.


Recipies.

https://github.com/Azure/azure-quickstart-templates/tree/master/quickstarts/microsoft.compute

https://github.com/Azure/azure-quickstart-templates/tree/master/quickstarts/microsoft.compute
https://www.google.com/search?channel=fs&client=ubuntu&q=main.iam.ad.ext.azure.com+%2Fapi%2FIntegratedApplications%2F

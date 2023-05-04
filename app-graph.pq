// This file contains your Data Connector logic
section AppScopeGraphConnector;


[DataSource.Kind="AppScopeGraphConnector", Publish="AppScopeGraphConnector.Publish"]
shared AppScopeGraphConnector.Contents = Value.ReplaceType(AppScopeGraphConnectorImpl, AppScopeGraphConnectorType);

AppScopeGraphConnectorType = type function(
    tenant as (type text meta [
        Documentation.FieldCaption = Extension.LoadString("TenantLabel"),
        Documentation.FieldDescription = Extension.LoadString("TenantDescription")
    ]),
    optional relativePath as (type text meta [
        Documentation.FieldCaption = Extension.LoadString("RelativePathLabel"),
        Documentation.FieldDescription = Extension.LoadString("RelativePathDescription"),
        Documentation.SampleValues = {"v1.0/users", "beta/security/alerts"}
    ])
) as table meta [
        Documentation.Name = Extension.LoadString("ConnectorName"),
        Documentation.LongDescription = Extension.LoadString("ConnectorDescription")
    ];


AppScopeGraphConnectorImpl = (tenant as text, optional relativePath as text) =>
    let
        tokenResponse = GetToken(tenant),
        headers = [#"Authorization"="Bearer "&tokenResponse[access_token]],

        result = OData.Feed("https://graph.microsoft.com/" & relativePath, headers, [Implementation="2.0"])
    in
        result;

GetToken = (tenant as text) =>
let 
    queryString = [
            grant_type = "client_credentials",
            client_id = Extension.CurrentCredential()[Username],
            client_secret = Extension.CurrentCredential()[Password],
            scope = "https://graph.microsoft.com/.default"
        ],
        tokenResponse = Json.Document(Web.Contents("https://login.windows.net/"&tenant&"/oauth2/v2.0/token", [
            Content = Text.ToBinary(Uri.BuildQueryString(queryString)),
            Headers = [
                #"Content-type" = "application/x-www-form-urlencoded",
                #"Accept" = "application/json"
            ],
            IsRetry = true,
            ManualStatusHandling = {400} 
        ]))
in
    tokenResponse;

// Data Source Kind description
AppScopeGraphConnector = [
    TestConnection = (dataSourcePath) as list => 
        let
            json = Json.Document(dataSourcePath),
            tenant = json[tenant]
        in
            {"AppScopeGraphConnector.Contents", tenant, "beta/users"},
    Authentication = [
         UsernamePassword = [
            UsernameLabel = "Client ID",
            PasswordLabel = "Client Secret"
         ]
    ],
    Label = Extension.LoadString("DataSourceLabel")
];

// Data Source UI publishing description
AppScopeGraphConnector.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { Extension.LoadString("ConnectorName"), Extension.LoadString("ConnectorDescription") },
    LearnMoreUrl = "https://powerbi.microsoft.com/",
    SourceImage = AppScopeGraphConnector.Icons,
    SourceTypeImage = AppScopeGraphConnector.Icons
];

AppScopeGraphConnector.Icons = [
    Icon16 = { Extension.Contents("pbi_custom_connector16.png"), Extension.Contents("pbi_custom_connector20.png"), Extension.Contents("pbi_custom_connector24.png"), Extension.Contents("pbi_custom_connector32.png") },
    Icon32 = { Extension.Contents("pbi_custom_connector32.png"), Extension.Contents("pbi_custom_connector40.png"), Extension.Contents("pbi_custom_connector48.png"), Extension.Contents("pbi_custom_connector64.png") }
];
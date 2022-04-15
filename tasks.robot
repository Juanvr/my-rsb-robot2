*** Settings ***
Documentation     Template robot main suite.

Library    RPA.JSON
Library    RPA.Salesforce
Library    RPA.Browser.Selenium
Library    RPA.HTTP
Library    RPA.Tables
Library    html_tables.py
Library    Collections
Library    RPA.PDF
Library    RPA.Archive
Library    String
Library    RPA.Dialogs
Library    RPA.Robocorp.Vault

*** Variables ***
${ConfigFile}    my-rsb-robot2.json

# *** Tasks ***
# Order robots from RobotSpareBin Industries Inc
#     Load Robot Configuration
#     Download Data
#     Open the robot order website
#     ${orders}=    Get orders
#     FOR    ${row}    IN    @{orders}
#         Close the annoying modal
#         Fill the form    ${row}
#         Preview the robot
#         Submit the order
#         ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
#         ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
#         Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
#         Go to order another robot
#     END
#     Create a ZIP file of the receipts

*** Tasks ***
Test Order robots from RobotSpareBin Industries Inc
    Load Robot Configuration
    # ${config.urlData}=    Ask User Orders CSV URL
    ${config.urlOrder}=    Get Url From Vault
    Download Data
    Open the robot order website
    Close the annoying modal
    ${dictModelsInfo}=    Get Models Table
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Fill the form    ${row}    ${dictModelsInfo}
        Preview the robot
        Submit the order
        ${receiptPath}=    Set Variable    ${config.receiptsOutputDir}${/}Receipt_${row}[Order number].pdf
        Store the receipt as a PDF file    ${receiptPath}
        ${screenShot}=    Take a screenshot of the robot
        Embed the robot screenshot to the receipt PDF file    ${screenShot}    ${receiptPath}
        Go to order another robot
        Close the annoying modal
    END
    Create a ZIP file of the receipts    ${config.receiptsOutputDir}     ${config.receiptsOutputZip} 



*** Keywords ***
Load Robot Configuration
    &{config}=    Load JSON from file    ${ConfigFile}
    Set Suite Variable    ${config}

Ask User Orders CSV URL
    Add text input    question    label=Url of CSV Data
    ${response}=    Run dialog
    [Return]    ${response.question}


Get Url From Vault
    ${secret}=    Get Secret    ${config.vaultName}

    [Return]    ${secret}[url]
Download Data
    Download    ${config.urlData}    ${config.pathData}    overwrite=True

Open the robot order website
    Open Available Browser    ${config.urlOrder}    
    
Get orders
    ${orders}=    Read table from CSV    ${config.pathData}
    [Return]    ${orders}

Close the annoying modal
    Click Button    OK

Get Models Table
    Click Button    Show model info
    Wait Until Page Contains Element    model-info
    ${html_table}=    Get Element Attribute    model-info    outerHTML
    ${table}=    Read Table From Html    ${html_table}
    
    ${dictModelInfo} =     Create Dictionary
    FOR    ${row}    IN    @{table}
        Set To Dictionary    ${dictModelInfo}   ${row}[${1}]    ${row}[${0}]
    END
    [Return]    ${dictModelInfo}

Fill the form
    [Arguments]    ${row}    ${dictModelInfo}
    Log    ${row}
    ${headNumber}=    Set Variable    ${row}[Head]
    ${headLabel}=     Set Variable    ${dictModelInfo}[${headNumber}] head
    Select From List By Label    head    ${headLabel}

    ${bodyNumber}=    Set Variable    ${row}[Body]
    ${bodyLabel}=     Set Variable    ${dictModelInfo}[${bodyNumber}] body
    Click Element     xpath://label[text()='${bodyLabel}']   

    Input Text    xpath://input[@placeholder='Enter the part number for the legs']    ${row}[Legs]
    Input Text    address    ${row}[Address]

Preview the robot
    Click Button    preview
Submit the order
    FOR    ${i}    IN RANGE    999999
        Click Button    order
        ${c} =   Get Element Count   receipt
        Exit For Loop If    ${c}>0
        Log    ${i}
    END

Store the receipt as a PDF file 
    [Arguments]    ${outputPath}
    ${receiptText}=     Get Element Attribute    receipt    outerHTML
    Html To Pdf    ${receiptText}     ${outputPath}

    
Take a screenshot of the robot
    ${screenShot}=    Capture Element Screenshot    robot-preview-image    temp.png
    [Return]    ${screenShot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}    ${pdf}
    # Close Pdf    ${pdf}
Go to order another robot
    Click Button    order-another

Create a ZIP file of the receipts
    [Arguments]     ${receiptsOutputDir}     ${receiptsOutputZip} 
    Archive Folder With Zip    ${receiptsOutputDir}    ${receiptsOutputZip} 
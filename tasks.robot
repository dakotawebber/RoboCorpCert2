*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library  RPA.Browser.Selenium
Library  RPA.HTTP
Library  RPA.Tables
Library  RPA.PDF
Library  RPA.Archive
Library  RPA.Dialogs
Library  RPA.Robocorp.Vault

*** Variables ***
${DOWNLOAD_DIR}=  ${CURDIR}${/}Downloads
*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${url}=  Get the vault data
    Open the robot order website  ${url}
    ${csv_file_path}=  Collect CSV location from user
    ${orders}=    Get orders  ${csv_file_path}
    FOR    ${row}    IN    @{orders}
        Close the annoying modal 
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds  1m  1s  Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts


*** Keywords ***
Get the vault data
    ${secret}=    Get Secret    data
    Log  ${secret}[url]
    RETURN  ${secret}[url]
Open the robot order website
    [Arguments]  ${url}
    Open Available Browser  ${url}

Get orders
    [Arguments]  ${csv}
    Log  Downloading CSV
    Download   ${csv}  ${DOWNLOAD_DIR}${/}orders.csv
    ${table}=    Read table from CSV    ${DOWNLOAD_DIR}${/}orders.csv
    Log   Found columns: ${table.columns}
    RETURN  ${table}

    
Close the annoying modal
    Click Button    OK

Preview the robot
    Click button  preview

Submit the order
    Click Button    order
    Page Should Contain Element    receipt

Go to order another robot
    Click Button  Order another robot

Store the receipt as a PDF file
    [Arguments]  ${order_number}
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html to Pdf  ${receipt_html}   ${DOWNLOAD_DIR}${/}order-${order_number}.pdf
    RETURN  ${DOWNLOAD_DIR}${/}order-${order_number}.pdf
    

Take a screenshot of the robot
    [Arguments]  ${order_number}
    Screenshot  css:div#robot-preview-image  ${DOWNLOAD_DIR}${/}order-${order_number}.png
    RETURN  ${DOWNLOAD_DIR}${/}order-${order_number}.png

Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Select Radio Button  body  ${row}[Body]
    Input Text   css:input[placeholder="Enter the part number for the legs"]  ${row}[Legs]
    Input Text  address  ${row}[Address]

Embed the robot screenshot to the receipt PDF file
    [Arguments]  ${screenshot}  ${pdf}
    
    ${finalPdf}=  Create List  ${screenshot}
    
    Add Files To Pdf  ${finalPdf}  ${pdf}  True
    
Create a ZIP file of the receipts
    Archive Folder With Zip    ${DOWNLOAD_DIR}    ${OUTPUT_DIR}${/}receipts.zip  recursive=True  include=*.pdf  exclude=*.png
    @{files}                  List Archive             ${OUTPUT_DIR}${/}receipts.zip
    FOR  ${file}  IN  ${files}
        Log  ${file} Added
    END

Collect CSV location from user
    Add heading  CSV File
    Add text input  url  label=CSV URL
    ${result}=  Run dialog
    RETURN    ${result.url}
    
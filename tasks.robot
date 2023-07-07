*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library    RPA.Browser.Selenium
Library           RPA.HTTP
Library    RPA.Tables
Library    RPA.Excel.Files
Library    RPA.RobotLogListener
Library    Collections
Library    RPA.FileSystem
Library    RPA.PDF
Library    RPA.Archive

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    create Directories
    Open the robot order website
    Download the csv file
    Get orders
    Close The Browser of order your robot
    Create a Zip File of the Receipts

*** Keywords ***
create Directories
    [Documentation]    This keyword creates folders for store images and pdfs
    Create Directory    ${CURDIR}${/}image_files
    Create Directory    ${CURDIR}${/}pdf_files
    Create Directory    ${CURDIR}${/}output
    Empty Directory    ${CURDIR}${/}image_files
    Empty Directory    ${CURDIR}${/}pdf_files
    Empty Directory    ${CURDIR}${/}output

Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Maximize Browser Window
    Set Selenium Speed    0.2
    Click Button   OK
    Wait Until Page Contains    Order your robot!

Download the csv file
    Download    https://robotsparebinindustries.com/orders.csv   ${CURDIR}${/}output  overwrite=True

Fill theform using csv file data
    [Arguments]     ${orders}
    [Documentation]   This keyword enters the details for oder your robot.
    Wait Until Element Is Visible    //*[@id="head"]
    Select From List By Value    //*[@id="head"]    ${orders}[Head]
    Select Radio Button    group_name=body    value=${orders}[Body]
    Input Text When Element Is Visible   //html/body/div/div/div[1]/div/div[1]/form/div[3]/input    text=${orders}[Legs]
    Input Text When Element Is Visible    //*[@id="address"]    ${orders}[Address]
Get orders
     ${orders}=    Read table from CSV    ${CURDIR}${/}output/orders.csv
    Log Many    ${orders}
    FOR    ${order}    IN    @{orders}
        Fill theform using csv file data    ${order}
        Wait Until Keyword Succeeds     10x     2s   preview the robot
        Wait Until Keyword Succeeds     10x     2s   submit the order
        Take a screenshot of the robot
        Embed the robot screenshot to the receipt PDF file
        Go to order another robot
        Close the annoying modal
    END

preview the robot
     [Documentation]  This keyword verifies after enter the details the robot image is diplayed
     Wait Until Element Is Visible    //*[@id="preview"]
     Click Button    //*[@id="preview"]
     Wait Until Element Is Visible    //*[@id="robot-preview-image"]

submit the order
    [Documentation]    This keyword submites the order of your robot
    Mute Run On Failure             Page Should Contain Element
    Wait Until Element Is Visible    //*[@id="order"]
    Click Button    //*[@id="order"]
    Page Should Contain Element    locator=//*[@id="receipt"]

Take a screenshot of the robot
     [Documentation]    This keyword capture the robot orderid
     Wait Until Element Is Visible    //*[@id="receipt"]/p[1]
     ${order_id}=  Get Text    //*[@id="receipt"]/p[1]
     Set Suite Variable    ${order_id}
     Wait Until Element Is Visible    //*[@id="robot-preview-image"]
     Capture Element Screenshot    //*[@id="robot-preview-image"]    ${CURDIR}${/}image_files${/}${order_id}.png
     ${Img_file}    Set Variable    ${CURDIR}${/}image_files${/}${order_id}.png
     Set Suite Variable    ${Img_file}

Close the annoying modal
    [Documentation]    This keyword close the alert meassage when we enters into order your robot page
    Wait Until Element Is Visible    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[2]
    Click Button   OK

Embed the robot screenshot to the receipt PDF file
    [Documentation]    This keyword creats one pdf and embede the robot image 
    Wait Until Element Is Visible   //*[@id="receipt"]
    Log    ${order_id}
    ${order_receipt_html}=          Get Element Attribute   //*[@id="receipt"]  outerHTML
    ${pdf_filename}    Set Variable    ${CURDIR}${/}pdf_files${/}${order_id}.Pdf
    Html To Pdf    ${order_receipt_html}      ${pdf_filename}
    Set Suite Variable    ${pdf_filename}
    Open Pdf    ${pdf_filename}
    @{myfiles}=       Create List     ${Img_file}:x=0,y=0
    Add Files To Pdf    ${myfiles}   ${pdf_filename}    true 
Go to order another robot
    [Documentation]    This keyword clicks the another robot button and navigates to robot order page
     Wait Until Element Is Visible    //*[@id="order-another"] 
     Click Button            //*[@id="order-another"]

Close The Browser of order your robot
    [Documentation]    This keyword close the broswer
    Close Browser

Create a Zip File of the Receipts
    [Documentation]    This keyword creates the zip folder with all the pds
    Archive Folder With Zip     ${CURDIR}${/}pdf_files   ${CURDIR}${/}output${/}pdf_archive.zip   recursive=True  include=*.pdf

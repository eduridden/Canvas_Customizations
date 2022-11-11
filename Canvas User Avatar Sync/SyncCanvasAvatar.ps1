##########################################################
# SINGLE USER AVATAR CANVAS SYNC
##########################################################
# @name         Single Canvas Avatar Sync
# @namespace      https://github.com/eduridden/Canvas_Customizations
# @version        1.0
# @author         Benjamin Selby (Github @benjaminselby)
# @Original Repo  https://github.com/benjaminselby/CanvasAvatarImageSync

Param(
    [Parameter(Mandatory=$true)]
    [string] $userCanvasId,
    # Folder where images will be exported to from Synergy, and read from by the Canvas API.
    [string] $imageFolder           = "$(Split-Path $MyInvocation.MyCommand.path)\Images",
    # Do not include a period before the file extension.
    [string] $imageFileExtension    = "jpg",
    # Image file MIME type.
    [string] $imageFileContentType  = 'image/jpeg',
    # Check if the image has been uploaded previously before proceeding?
    [string] $doCheckSyncHistory    = 'Y',
    # Get profile picture from a Synergy export (set to 'N' if image has already been saved to folder)?
    [string] $doExportProfilePic    = 'Y',
    # Update image sync database with info for the file we will upload?
    [string] $doUpdateSyncHistory   = 'Y',
    [string] $token                 = '<YOUR_API_TOKEN>'
)


# Authentication header for API calls.
$headers    = @{Authorization="Bearer $token"}


#########################################################################################################
# FUNCTIONS
#########################################################################################################


Function AssignAvatarImage {

    param(
        [Parameter(Mandatory=$true)] $userCanvasId,
        [Parameter(Mandatory=$true)] $fileUuid
    )

    # Get a list of the available avatar images.
    # Note that if the user does not currently have a PROFILE PICTURES folder, this should create it.
    try {
        $avatarRequestUrl = "https://<DOMAIN>:443/api/v1/users/$userCanvasId/avatars?as_user_id=$userCanvasId"
        $availableAvatars = Invoke-RestMethod `
            -URI $avatarRequestUrl `
            -headers $headers `
            -method GET `
            -FollowRelLink
    } catch [Microsoft.PowerShell.Commands.HttpResponseException] {
        Write-Error "ERROR: The URL [$avatarRequestUrl] is invalid. `nMESSAGE: $($_.Exception.Message)"
        Return $false
    } catch {
        Write-Error "ERROR: An unknown error occurred when requesting available avatars. `nMESSAGE: $($_.Exception.Message)"
        Return $false
    }

    # If we find an available avatar image with the corresponding UUID, assign it as the avatar pic.
    foreach($image in $availableAvatars) {

        if ($image.uuid -EQ $fileUuid) {

            try {

                Write-Verbose "Assigning image file with IMAGE_TOKEN: $($image.token) as user avatar."

                $setAvatarUri = "https://<DOMAIN>:443/api/v1/users/$($userCanvasId)?user[avatar][token]=$($image.token)"
                $setAvatarResponse = Invoke-RestMethod `
                    -Uri $setAvatarUri `
                    -Method Put `
                    -Headers $headers `
                    -FollowRelLink

                Break

            } catch [System.Net.Http.HttpRequestException] {
                Write-Error "ERROR: Could not PUT to URI [$setAvatarUri]. `nMESSAGE: $($_.ErrorDetails.Message)"
                Return $false
            }
            catch {
                Write-Error "ERROR: An unexpected error occurred during avatar assignment. `nMESSAGE: $($_.ErrorDetails.Message)"
                Return $false
            }
        }
    }

    if ($setAvatarResponse -EQ $nothing) {
        Write-Verbose "There was a problem assigning an avatar from the available list of images."
        Write-Verbose (($availableAvatars | foreach-object {$_.url}) -join "`n")
        Return $false
    } elseif ($setAvatarResponse.avatar_url -MATCH "^https://<DOMAIN>.images/thumbnails/\d+/$fileUuid$") {
        Write-Verbose "OK, avatar assigned successfully."
        Return $true
    } else {
        Write-Verbose "ERROR: There was a problem assigning the avatar. Current avatar URL: $($setAvatarResponse.avatar_url)."
        Return $false
    }
}


#########################################################################################################
# MAIN
#########################################################################################################


Write-Output "Trying to get Synergy ID for Canvas user: $userCanvasId"

try {

    $getUserInfoUri = "https://<DOMAIN>:443/api/v1/users/$userCanvasId"
    $userObject = Invoke-RestMethod `
        -Uri  $getUserInfoUri `
        -Method GET `
        -Headers $headers `
        -FollowRelLink

} catch [Microsoft.PowerShell.Commands.HttpResponseException] {
    Write-Output "ERROR: Resource at URI: [$getUserInfoUri] is not available.`nMESSAGE: $($_.ErrorDetails.Message)"
    Return
} catch  {
    Write-Output "ERROR: Unknown error occurred while getting user info.`nMESSAGE: $($_.ErrorDetails.Message)"
    Return
}

if ($userObject -EQ $nothing) {
    Write-Output "ERROR: No user object was obtained for user with Canvas ID: $userCanvasId `nExiting process."
    Return
} elseif ($userObject.sis_user_id -EQ $nothing) {
    Write-Output "ERROR: Canvas user $userCanvasId has no SIS ID. `nExiting process."
    Return
} elseif ($userObject.sis_user_id -NOTMATCH '^\d+$') {
    Write-Output "ERROR: Canvas user $userCanvasId has an invalid Synergy ID: $($userObject.sis_user_id). `nExiting process."
    Return
}

$userName           = $userObject.name
$userSynergyId      = $userObject.sis_user_id
$currentAvatarUrl   = $userObject.avatar_url

Write-Output "Checking avatar image for $userName (Synergy ID:$userSynergyId Canvas ID:$userCanvasId)."
Write-Output "CurrentAvatar: $currentAvatarUrl"

# Image files are currently exported as JPEGs with our numeric Synergy user ID as the file name.
$imageFileName  = "$userSynergyId.$imageFileExtension"
$imageFilePath  = "$imageFolder\$imageFileName"


#############################################################################################################


Write-Output "Checking sync history."

# Check the user's current avatar image against the sync history stored in our DB.

# If the user's current AVATAR_URL is of the form: 'https://<DOMAIN>/images/thumbnails/<FILE_ID>/<FILE_UUID>',
# then it points to an uploaded image.
# If the avatar image is empty, AVATAR_URL will contain the default URL: 'https://<DOMAIN>/images/messages/avatar-50.png'

if ($currentAvatarUrl -MATCH 'https://<DOMAIN>.images/thumbnails/.+/.+') {
    $currentAvatarFileId, $currentAvatarUuid = $currentAvatarUrl.Replace('https://<DOMAIN>/images/thumbnails/', '').split('/')
    Write-Output "Current Canvas avatar FILE_ID: $currentAvatarFileId UUID: $currentAvatarUuid"
} elseif ($currentAvatarUrl -MATCH 'https://<DOMAIN>/images/messages/avatar-50.png') {
    Write-Output "Default avatar in place for this user - URI: $currentAvatarUrl"
    $currentAvatarFileId, $currentAvatarUuid = $nothing, $nothing
} else {
    Write-Output "Unrecognised current avatar image - URI: $currentAvatarUrl"
    $currentAvatarFileId, $currentAvatarUuid = $nothing, $nothing
}

# This returns a database record containing the fields: {UserId, DateModified, CanvasFileId, CanvasFileUuid}
# If a user's avatar has been uploaded by us in the past, this table will contain information about the
# file that was uploaded.
$avatarSyncHistory = Invoke-Sqlcmd `
    -server <DB_SERVER_NAME> `
    -database CanvasAdmin `
    -query "select * from dbo.AvatarImageSync where UserId = $userSynergyId"

if ($avatarSyncHistory -EQ $nothing) {
    Write-Output "No previous upload data found for this user in the avatar sync DB table."
} elseif ($avatarSyncHistory.DateModified -LT (Get-Date).AddMonths(-1)) {
    Write-Output "Previous avatar sync was at $($avatarSyncHistory.DateModified.Tostring('dd.MM.yyyy HH:mm'))."
    Write-Output "Sync has expired. Overwrite existing avatar image."
} elseif ($currentAvatarUuid -EQ $avatarSyncHistory.CanvasFileUuid) {
    Write-Output "Sync history info: FILE_ID: $($avatarSyncHistory.CanvasFileId) UUID: $($avatarSyncHistory.CanvasFileUuid)"
    Write-Output "User's current avatar matches information in the avatar sync DB table."
    Write-Output "Nothing to do."
    Return
} else {
    Write-Output "Sync history info: FILE_ID: $($avatarSyncHistory.CanvasFileId) UUID: $($avatarSyncHistory.CanvasFileUuid)"
    Write-Output "User's current avatar DOES NOT MATCH information in the avatar sync history DB table."

    # We do have history of an avatar upload which occurred at some point in the past, so check
    # to see if this user still has the previously uploaded file in their available avatars list.
    Write-Output 'Checking if the correct avatar image from a previous upload is still available to assign.'
    if (AssignAvatarImage -userCanvasId $userCanvasId -fileUuid $($avatarSyncHistory.CanvasFileUuid))  {
        Write-Output "OK, an existing profile image was assigned as the user avatar. Finished."
        Return
    } else {
        Write-Output "No currently available avatar image "
    }
}

Write-Output "Proceeding with image sync."


#########################################################################################################


if ($doExportProfilePic) {

    Write-Output "Extracting user's profile photo from Synergy to path: $imageFilePath"

    $sqlGetSynergyProfileImage = "
        exec dbo.spsExportSynergyProfileImage
            @UserId             = $userSynergyId,
            @ExportFolderPath   = '$imageFolder',
            @FileName           = '$imageFileName'"

    $imageExportProcess = Invoke-Sqlcmd `
        -server <DB_SERVER_NAME> `
        -database CanvasAdmin `
        -query $sqlGetSynergyProfileImage

    if ($imageExportProcess.ReturnValue -EQ 0) {
        Write-Output "No image file was exported from Synergy for this user. Exiting."
        Return
    } elseif ($imageExportProcess.ReturnValue -EQ 1) {
        Write-Output "Image file exported from Synergy successfully to [$imageFolder\$imageFileName]."
    } else {
        Write-Output "ERROR: Unknown return value from image export SQL procedure. Exiting process."
        Return
    }
}


#########################################################################################################


Write-Output "Getting data for the user's PROFILE PICTURES folder in Canvas."

try {
    $folderInfoUri = "https://<DOMAIN>:443/api/v1/users/$userCanvasId/folders?as_user_id=$userCanvasId"
    $canvasFoldersInfo = Invoke-RestMethod `
        -uri $folderInfoUri `
        -method GET `
        -headers $headers `
        -FollowRelLink
} catch [Microsoft.PowerShell.Commands.HttpResponseException] {
    Write-Output "ERROR: Resource at URI: [$folderInfoUri] is not available. `nMESSAGE: $($_.ErrorDetails.Message)"
    Return
} catch  {
    Write-Output "ERROR: Unknown error occurred while getting user info. `nMESSAGE: $($_.ErrorDetails.Message)"
    Return
}

$profilePicturesFolder = $canvasFoldersInfo | ForEach-Object {$_} | Where-Object {$_.name -MATCH 'profile pictures'}

if ($profilePicturesFolder -EQ $Nothing) {

    Write-Output "Could not obtain PROFILE PICTURES folder info. Attempting to create."

    try {
        # The following request should create the PROFILE PICTURES folder if it doesn't already exist.
        Invoke-RestMethod `
            -URI "https://<DOMAIN>:443/api/v1/users/$userCanvasId/avatars?as_user_id=$userCanvasId" `
            -headers $headers `
            -method GET `
            | Out-Null

        # Try to get PROFILE PICTURES folder again...
        $canvasFoldersInfo = Invoke-RestMethod `
            -uri "https://<DOMAIN>:443/api/v1/users/$userCanvasId/folders?as_user_id=$userCanvasId" `
            -method GET `
            -headers $headers `
            -FollowRelLink
    } catch  {
        Write-Output "ERROR: Unknown error occurred while attempting to create PROFILE PICTURES folder. `nMESSAGE: $($_.ErrorDetails.Message)"
        Return
    }

    $profilePicturesFolder = $canvasFoldersInfo | ForEach-Object {$_} | Where-Object {$_.name -MATCH 'profile pictures'}

    if ($profilePicturesFolder -EQ $Nothing) {
        # This can happen when a user has not verified their email by clicking a link mailed to them by Canvas.
        # It can also happen when the student's PROFILE PICTURES folder is 'locked' for whatever reason.
        # In this case, the folder needs to be 'published'. I tend to do this manually through the Canvas interface,
        # but it might be possible to do this via API.
        Write-Output "ERROR: Could not create PROFILE PICTURES folder. Aborting avatar image sync."
        Write-Output "(This can be caused by a user not activating their Canvas account correctly via email link). Exiting."
        Return
    }
}

Write-Output "Got PROFILE PICTURES folder with ID $($profilePicturesFolder.id)"


#########################################################################################################


Write-Output "Initiating file upload process - Notification."

$fileSize = (Get-Item $imageFilePath).Length

try {
    # Checking user's file quota before upload. If there is not enough room we cannot upload the image file.
    $quotaResponse = Invoke-RestMethod `
        -uri "https://<DOMAIN>:443/api/v1/users/$userCanvasId/files/quota?as_user_id=$userCanvasId" `
        -Method GET `
        -headers $headers `
        -FollowRelLink
} catch [Microsoft.PowerShell.Commands.HttpResponseException] {
    Write-Output "ERROR: Resource at URI: [$folderInfoUri] is not available.`nMESSAGE: $($_.ErrorDetails.Message)"
    Return
} catch  {
    Write-Output "ERROR: Unknown error occurred while getting user info.`nMESSAGE: $($_.ErrorDetails.Message)"
    Return
}

$quotaRemaining = $quotaResponse.quota - $quotaResponse.quota_used

if ($quotaRemaining -LT $fileSize) {
    Write-Output "ERROR: User does not have sufficient file quota to enable upload."
    Write-Output ("QUOTA: {0,15:n0} bytes" -f $quotaResponse.quota)
    Write-Output ("USED:  {0,15:n0} bytes" -f $quotaResponse.quota_used)
    Return
}

try {

    $form = @{
        name = $imageFileName
        # Include file size here to enable quota warnings.
        size = $fileSize
        # If CONTENT_TYPE is omitted it will be guessed based on file extension, but
        # I prefer to set it manually.
        content_type = $imageFileContentType}

    $fileUploadNotify = Invoke-RestMethod `
        -URI "https://<DOMAIN>:443/api/v1/folders/$($profilePicturesFolder.id)/files?as_user_id=$userCanvasId" `
        -headers $headers `
        -method POST `
        -form $form `
        -FollowRelLink

} catch [Microsoft.PowerShell.Commands.HttpResponseException] {
    Write-Output "ERROR: Upload Notification refused.`nMESSAGE: $($_.ErrorDetails.Message)"
    Return
} catch  {
    Write-Output "ERROR: Unknown error occurred during upload notification.`nMESSAGE: $($_.ErrorDetails.Message)"
    Return
}

# The UPLOAD_URL has a life span of 30 minutes, and cannot be used after timeout.
# The RESPONSE  content contains a list of parameters called UPLOAD_PARAMS which
# should be included in the POST submission body along with the file data when the file
# is subsequently uploaded.
# Currently [28/08/2020], these parameters are FILENAME and CONTENT_TYPE.
$uploadUri = $fileUploadNotify.upload_url


#########################################################################################################


Write-Output "Uploading file data."

try {
    # I originally programmed this to upload image file data using Powershell's Invoke-RestMethod, but I have found this to be unreliable.
    # It sometimes results in the MIME type of images being not recognised correctly by Canvas, which means that
    # the uploaded image is not available to assign as a user avatar.
    # I can't figure out why this happens (it may have something to do with the way that Invoke-RestMethod combines
    # FORM elements into an HTTP request payload).
    # I am using CURL for the time being instead because it seems more reliable.

    $curlResponse = curl -X POST "$uploadUri" -F "file=@$imageFilePath"
    $fileUploadResponse = $curlResponse | Convertfrom-Json

} catch [System.Management.Automation.ItemNotFoundException] {
    Write-Output "ERROR: File [$imageFilePath] not found. Upload aborted.`nMESSAGE: $($_.ErrorDetails.Message)"
    Return
} catch {
    Write-Output "ERROR: Unknown error occurred during file upload.`nMESSAGE: $($_.ErrorDetails.Message)"
    Return
}

# If the file has uploaded successfully, the response object will contain information about the uploaded file.
if ($fileUploadResponse.id -EQ $nothing) {
    Write-Output "ERROR: File upload failed for an unknown reason."
    Write-Output $error[0]
    Return
}

Write-Output "$($fileUploadResponse.size) bytes uploaded."

$canvasFileId     = $fileUploadResponse.id
$canvasFileUuid   = $fileUploadResponse.uuid

Write-Output "Uploaded FILE_ID: $canvasFileId UUID: $canvasFileUuid"


#########################################################################################################


Write-Output "Begin assignment of uploaded file as user's avatar."

if( (AssignAvatarImage -userCanvasId $userCanvasId -fileUuid $canvasFileUuid) -NE $true ) {
    Write-Output "ERROR: Avatar image assignment failed."
    Return
}

Write-Output "Avatar image assigned successfully."


#########################################################################################################


if($doUpdateSyncHistory) {

    Write-Output "Saving FILE_ID: $canvasFileId and UUID: $canvasFileUuid for this upload to DB."

    $sqlAvatarImageInsert = "
        exec dbo.spiuAvatarImageUpload
            @UserId         = '$userSynergyId',
            @CanvasFileId   = '$canvasFileId',
            @CanvasFileUuid = '$canvasFileUuid'"

    $saveSyncData = Invoke-Sqlcmd `
        -server <DB_SERVER_NAME> `
        -database CanvasAdmin `
        -query $sqlAvatarImageInsert

    if ($saveSyncData.ReturnValue -EQ 0) {
        Write-Output "ERROR: Could not save avatar sync data for this user."
        Return
    }
}

Write-Output "Finished image sync for this user. Exiting."

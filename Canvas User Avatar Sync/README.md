# Bulk Upload Canvas Avatars with PowerShell

##Attribution Information

**Author:** Benjamin Selby
**Original Source:** <https://github.com/benjaminselby/CanvasAvatarImageSync>
**Canvas Discussion:** <https://community.canvaslms.com/t5/Canvas-Developers-Group/How-to-bulk-load-and-update-avatar-profile-pictures-with/ba-p/410101>

##Description

The file which does the bulk of the work is #SyncCanvasAvatar.ps1#. This syncs an avatar image for a single Canvas user.

The file *CanvasAvatarSyncAll.ps1* is the script which is called by Windows Task Scheduler. It obtains a list of all Canvas users in our domain, then loops through every one and syncs avatar images for all users with valid SIS ids. Anyone without a valid SIS ID is ignored (our Synergy database stores user images based on SIS ID lookup).

I will walk through the code a little bit below. Our in-house solution has quite a few lines which are mostly concerned with message logging and error handling, so it's arguably longer than it needs to be. It also produces a very verbose log, which I found helpful during debugging, but they could obviously be removed if you don't want this.

I don't profess to be a Powershell expert, or a great programmer, so if anyone has feedback or comments, please let me know.

##Requirements
To operate it is required you have Powershell 7 and Curl installed.

##How it Works

A summary of the script's activity is:

1. Get the user's SIS ID and other information from Canvas. This script updates the avatar image for a single user. So, you need another script which calls this one for every user you want to update. I do this by getting a list of all Canvas user IDs via an API call, then call this script for each one. Of course, there are a lot of users, and not all of them have photos stored in Synergy. If no photo is exported for a user, this script will skip them.

2. Check 'Sync History'. One thing I wanted to avoid was re-uploading the same image file over and over again (inefficient). So, when the script uploads an avatar image successfully, it updates a database table with information about the user, the image which was uploaded, and the datetime of the upload. So, the script checks a user's current avatar by obtaining the user's current avatar URL. Avatar URLs contain both the Canvas ID of the image file which was assigned as that user's avatar, and also that file's UUID. If the user's current avatar URL information matches the information we have stored in our Sync History database table, then we know it's the image we uploaded previously (ie. the correct image). In this case, the script exits because there is no work to do. Also, if the user's current avatar URL is the 'default' URL, then we need to upload an image.

Also, we have a timeout on image uploads - once they are a month old, we download a new image from Synergy and re-upload it. So, if a student's photo changes (our school photos are updated every year), it will always be updated on Canvas within a month.

3. Export the user's photo from Synergy. We use Synergy as our main SIS solution. Staff and student photos are stored in that database. I have created a stored process attached to the database which exports a user's photo to a folder, with the Synergy ID of that user as the file name. So, the script looks up the SIS id for the user, based on their Canvas ID, and then uses this to call the stored process which exports the picture from the database. All the stored process calls in this script use default Windows authentication for the current user. (You will need to organise your own image export - I haven't posted the stored process code at this point, but I might do in the future).

4. Upload the photo to Canvas and save in the user's Profile Pictures folder. If the user doesn't have a Profile Pictures folder, the script will attempt to create it. I've only had a couple of problems with this - for some reason, one student's Profile Pictures folder was locked (no idea how that happened). Some other users haven't even activated their Canvas accounts (by clicking the link in their activation email), in which case this won't be possible.

Image file uploading can be a bit tricky. I've covered this in other posts:

<https://community.canvaslms.com/t5/Developers-Group/How-to-Upload-an-Assignment-via-API-using-Powers>

<https://community.canvaslms.com/t5/Question-Forum/How-to-upload-a-file-via-API-using-Powershell/m-p/>

There is a two-phase process where you start by notifying of your intent to upload, which returns a URL. You then send the file data to that URL (which has a life span of 30 minutes).

Before uploading, this script checks the user's file quota remaining to see if there's enough room to upload the file. If not, an error is returned. I have another script which checks all user file quotas on a weekly basis so I can harass users who have exceeded their quotas... 😉

5. Assign the image as the user's avatar. This is a two-step process. You need to get a list of available avatar images, then cycle through each one to find the file you just uploaded. Any images in the user's Profile Pictures folder should be 'available'. The correct image is identified by UUID, which was returned when you uploaded the image data in the previous step.

Also, another possibility is that we have previously uploaded the 'correct' image, but the user changed it. In this case, the correct image should still be in the user's Profile Pictures folder, and so it will still appear in the user's available avatars list. In this case, we don't need to upload anything - just reassign the correct avatar.

6. Once we have successfully uploaded and assigned the correct avatar, we update our Sync History database table with the information from this process. This script runs every night, so when a user's avatar is unchanged it matches the info we have in our database, which means we don't need to re-upload the file.

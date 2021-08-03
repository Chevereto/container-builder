# Updating

The update process consist in that you pull our `chevereto/container-builder` repo changes for updating the Dockerfile. From there you can re-build the image, with the updated changes.

## One-click updating

1. Go to **Actions**
2. Select **Update** under **Workflows**
3. Click on **Run Workflow** and confirm

![Update template](src/update.png)

🤖 When done **a bot will create a pull request** in your repo so you can review and confirm the changes.

![Update template](src/update-merge.png)

## Manual updating

Refer to the [CONSOLE GUIDE](guides/console/UPDATING.md).

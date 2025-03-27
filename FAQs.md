# FAQs

## Common Issues

### R Shiny Server

If some of the plot images will not display on the server hosted application. To resolve the issue, please see the commands provided in the update_shiny.sh script in the util directory of the freeCount GitHub repository. Those are the commands needed to run to fix the issue. 

/srv/ is root level, so it's not open to write by default. This is where shiny-server always sticks stuff by default, so if any shiny needs to make files as in our graphs, the specific folders need to be opened by the 'shiny' id.

Recommendation is to only open what you need for security reasons, especially since this folder is web-facing.

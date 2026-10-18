#   Money Talks
## Personal Finances Managment

### Specifications
#### Settings.view
The Settings view is one of the three destinations in the sidebar (Inbox, Wallets, Settings). It offers maintenance actions to clean up the app's data in one step.
**User Story: As a user, I want to delete all revenues or all wallets from a single place, so that I can reset parts of my data without removing items one by one.**
How it works
When I open the Settings view, I see a *Maintenance* section with two buttons:
**Delete All Revenues**
* **Delete All Wallets**

Each button is only available while there are items to delete; if a list is already empty, its button is disabled. Below the section, a note reminds me that deleted items cannot be recovered.
When I click one of the buttons, a confirmation dialog appears that tells me how many items will be deleted. I can close the dialog with *Cancel* without any change, or confirm with *Delete*.
**Delete All Revenues** removes every revenue. The Inbox then shows the empty state ("No Revenues"). Wallets are not affected.
* **Delete All Wallets** removes every wallet. The Wallets view then shows the empty state ("No Wallets"). All revenues that pointed to a wallet lose that assignment, and their wallet confirmation is revoked as well — so those revenues show up again in the Inbox instead of staying hidden as "confirmed".

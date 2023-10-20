
# Change Log
All notable changes to this project will be documented in this file.
 
## [0.1.8] - 11-10-23
 
### Added
- Added the changelog file
- Gui for train depot settings
 
### Changed
- refactored all lists to go to one single comprehensive list for ease of access (global.train_table)
- immidiately hid the GUI so it wont be used, done this to publish some stability updates before finishing the GUI

### Fixed
- Fixed a rare bug where the train_depots table wasn't yet initialized which would crash the game if it occured.
- Fixed a typo in the settings file
- Fixed another typo in the settings file

## [0.1.9] - 11-10-23

### Added


### Changed


### Fixed
- a bug which caused the depot_array to not yet be made when it was called

## [0.1.10] - 11-10-23

### Added
- command to send all trains away from the depot

### Changed
- changed the way the train list is updated
- added a few checks to stop the mod deleting the wrong stations

### Fixed
- the mod didnt work when used for the first time
- the mod didnt update properly

## [0.1.11] - 15-10-23

### Added

### Changed
- Changed the settings tooltips to show that adding multiple station names won't break the mod anymore

### Fixed
- Added some checks to make sure the table didnt get confused when a player manually removes the depot station
- Removed some points where the mod tried to read the depot directly from the settings instead of the table

## [0.1.12] - 17-10-23

### Added

### Changed

### Fixed
- A bug which would crash the server if you changed the schedule of a train manually, line 563 - 566

## [0.2.0] - 18-10-23

### Added
- GUI!
- Enable, disable the train depots mod for that train and select the station it should go to

### Changed
- For some reason the mod had two functions to check for trains, merged these two

### Fixed
- In the on_train_state_changed callback the mod compared the value of global.train_table.selected_depot instead of global.train_table[event.train.id].selected_depot

## [0.2.1] - 19-10-23

### Added

### Changed
- Tweaked some values in settings.lua

### Fixed
- Bug that had the train table incomplete for some reason 

## [0.2.2] - 20-10-23

### Added

### Changed

### Fixed
- A bug that would occur on removing a train while the gui was opened which wouldnt remove the screen element

## [0.2.3] - 20-10-23

### Added

### Changed

### Fixed
- Fixed a weird bug in which remove_stop_from_schedule would be trying to index a nil value


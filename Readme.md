# RCD - Rapid Conjured Depositor

**RCD** is a high-performance automation utility for WoW 3.3.5 (specifically tailored for Project Epoch) that streamlines the process of depositing conjured items into the Guild Bank. It utilizes a sophisticated state-machine logic to bypass standard restrictions using placeholder items.

## Features

- **Automated Exploitation**: Automatically handles the "deposit -> withdraw -> swap" loop to place conjured items into the bank.
- **Dynamic Planner**: Scans your bags and builds an optimized processing queue before starting.
- **Smart Placeholder Search**: Intelligent retry logic ensures the addon waits for your placeholder items to return to your bags before continuing.
- **Native-Style UI**:
  - **Integrated Bottom Tab**: A text-based tab anchored to the Guild Bank frame that matches the native "Bank" and "Log" tabs.
  - **ElvUI Support**: Built-in skinning support for ElvUI users.
  - **Quick-Settings Menu**: Right-click the RCD tab to manage your configuration without chat commands.
  - **Rich Tooltips**: Detailed hover information showing current filters and processing speed.
- **Customizable Filters**:
  - **Item Lists**: Maintain persistent lists of allowed placeholders and swap targets.
  - **Wildcard Support**: Use the "Any" option to match broad categories (e.g., any conjured food).
  - **Item ID Support**: Use exact Item IDs for precise filtering.

## Installation

1. Download the repository.
2. Place the `RCD` folder into your `Interface\AddOns\` directory.
3. Restart your game or reload your UI (`/reload`).

## Usage

1. Open your **Guild Bank**.
2. Click the **RCD Tab** in the bottom-right corner to start/stop the automation.
3. **Right-click** the RCD tab to open the configuration menu:
    - Add new placeholders (e.g., Coal).
    - Add new swap targets (e.g., Conjured Mana Bread).
    - Adjust the processing delay (25ms - 500ms+).

### Chat Commands

While the UI is recommended, you can also use:

- `/rcd start` - Start the process.
- `/rcd stop` - Stop the process, in case it loops for whatever reason.

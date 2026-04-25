# RCD - Rapid Conjured Depositor

**RCD** is an addon which greatly speeds up the process of depositing conjured items such as Mage food or Warlock Healthstones to the Guild Bank on Project Epoch.

## Features

- **Automated Deposit Loop**: Automatically handles the "deposit -> withdraw -> swap" loop to place conjured items into the bank.
- **Continuous Mode EXPERIMENTAL**: Supports infinite deposit loops. When enabled, the addon stays active and automatically detects/deposits new items as they appear in your inventory (ideal for Mage Tables).
- **Dynamic Planner**: Scans your bags and builds an optimized processing queue before starting.
- **Smart Placeholder Search**: Intelligent retry logic ensures the addon waits for your placeholder items to return to your bags before continuing.
- **Native-Style UI**:
  - **Integrated Bottom Tab**: A text-based tab anchored to the Guild Bank frame that matches the native "Bank" and "Log" tabs.
  - **ElvUI Support**: Built-in skinning support for ElvUI users.
  - **Quick-Settings Menu**: Right-click the RCD tab to manage your configuration without chat commands.
  - **Rich Tooltips**: Detailed hover information showing current filters, processing speed, and continuous status.
- **Customizable Filters**:
  - **Item Lists**: Maintain persistent lists of allowed placeholders and swap targets.
  - **Wildcard Support**: Use the "Any" option to match broad categories (e.g., any conjured food).
  - **Item ID Support**: Use exact Item IDs for precise filtering.

## Installation

1. Download the repository.
2. Place the `RCD` folder into your `Interface\AddOns\` directory.
3. Restart the game.

## Usage

1. Open your **Guild Bank**.
2. Click the **RCD Tab** in the bottom-right corner to start/stop the automation.
3. **Right-click** the RCD tab to open the configuration menu:
    - Toggle **Continuous Mode** (for Mage Tables).
    - Add new placeholders (e.g., Coal).
    - Add new swap targets (e.g., Conjured Mana Bread).
    - Adjust the processing delay (25ms - 500ms+).

### Mage Table Workflow
1. Create a Mage Table next to the Guild Bank.
2. Enable **Continuous Mode** in the RCD options.
3. Start RCD.
4. Hover your mouse over the Mage Table and **manually click** (or use an "Interact with Mouseover" keybind) to restock your food.
5. RCD will automatically detect the new stacks and deposit them instantly, looping until you stop it or the bank is full.

### Chat Commands

While the UI is recommended, you can also use:

- `/rcd start` - Start the process.
- `/rcd stop` - Stop the process, in case it loops for whatever reason.

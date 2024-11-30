# Root Motion Public

This project is a demo for networked root-motion player characters. While using the NetFox plugin, it makes sure the networked player characters are always in-sync with the network, and attempts to make the movement as smooth as possible.

## Features
- Networked root-motion player characters
- NetFox integration

## How to use
1. Open the project in Godot 4.3
2. Launch three instances of the runner.
   - Press Debug > "Customize Run Instances"
   - First runner set the feature tags to: `dedicated_server`
   - The other runners don't need any configuration.
3. Press the play button in the editor.
4. In the clients, press "Connect"
# VSD OpenLane Codespace

A ready-to-use **cloud workspace** to learn and run **Physical Design using OpenLane and Magic** — right inside your browser.
No installation needed. Works on any laptop.

---

## 1. Launch Your Codespace

Click **“Create Codespace on main”** to start the setup.
This automatically builds a virtual Linux environment with OpenLane, Magic, and GUI support.

![Launch Codespace](images/01_launchCodeSpace.jpg)

---

## 2. Codespace Builds Automatically

The setup installs all required dependencies, including the Sky130 PDK.
Wait for `[VSD OPENLANE CODESPACE setup]` to appear — it confirms successful installation.

![Codespace Log](images/02_codespaceLog.jpg)

---

## 3. Open the Terminal

Once the build completes, open a new terminal tab and you’ll see a welcome message confirming the container is ready.

![Setup Complete](images/03_CodespaceCreationCompleteAndOpenTerminal.jpg)

---

## 4. Test OpenLane Installation

Run the following commands to verify everything works:

```bash
cd ~/Desktop/OpenLane
make test
```

This command runs a test design through the complete OpenLane flow.

![Test OpenLane](images/04_testOpenlaneInstallation.jpg)

---

## 5. Confirm Successful Flow

If setup is correct, you’ll see:

```
[SUCCESS]: Flow complete.
[INFO]: There are no setup or hold violations in the design.
```

Now, go to the **Ports** tab — port `6080` will appear with label *noVNC Desktop*.
Click the **globe icon 🌐** to open the GUI.

![Test Design & VNC](images/05_TestDesignSucessfulyCompleteAndStepsToOpenVNC.jpg)

---

## 6. Open the noVNC Desktop

A new browser tab will open with the VSD desktop environment.

![noVNC Desktop](images/06_openVNC.jpg)

If you see a directory listing, click **`vnc_lite.html`** or **`vnc.html`** to launch the XFCE desktop.

![vnc lite](images/07_vnc_lite.jpg)

---

## 7. Launch Magic and View Layout

Inside the VNC desktop, open a terminal and navigate to your design folder:

```bash
cd ~/Desktop/OpenLane/designs/spm/runs/openlane_test/results/final
magic -T /home/vscode/.ciel/sky130A/libs.tech/magic/sky130A.tech
```

![Launch Magic](images/08_DirectoryStructureAndLaunchMagic.jpg)

---

## 8. Load the LEF and DEF Files

In Magic’s console, load the layout files:

```tcl
lef read ../../../tmp/merged.nom.lef
def read ./def/spm.def
```

You can now visualize your design layout!

![LEF Read](images/09_lefRead.jpg)
![DEF Read](images/10_defRead.jpg)

---

## ✅ That’s It!

You’ve successfully:

1. Created a browser-based OpenLane environment
2. Completed a physical design flow
3. Viewed layout in Magic via noVNC

---

### 💡 Tips for Students

* Always start from the **Ports** tab if the GUI closes — reopen `6080`.
* Use `make test` to re-run the design anytime.
* Use `magic` to explore the layout, zoom in, and understand each cell.
* No local installation needed — just your browser.


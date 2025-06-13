# windows

### How do I use it?
Very simple! These are the steps:
 * Start the container and connect to port 8006⁠ using your web browser.
 * Sit back and relax while the magic happens, the whole installation will be performed fully automatic.
 * Once you see the desktop, your Windows installation is ready for use.

Enjoy your brand new machine, and don't forget to star this repo!

### How do I select the Windows version?
By default, Windows 11 Pro will be installed. But you can add the VERSION environment variable to your compose file, in order to specify an alternative Windows version to be downloaded:
```yml
environment:
  VERSION: "11"
```

Select from the values below:

  | **Value** | **Version**            | **Size** |
  |---|---|---|
  | `11`   | Windows 11 Pro            | 5.4 GB   |
  | `11l`  | Windows 11 LTSC           | 4.7 GB   |
  | `11e`  | Windows 11 Enterprise     | 4.0 GB   |
  ||||
  | `10`   | Windows 10 Pro            | 5.7 GB   |
  | `10l`  | Windows 10 LTSC           | 4.6 GB   |
  | `10e`  | Windows 10 Enterprise     | 5.2 GB   |
  ||||
  | `8e`   | Windows 8.1 Enterprise    | 3.7 GB   |
  | `7u`   | Windows 7 Ultimate        | 3.1 GB   |
  | `vu`   | Windows Vista Ultimate    | 3.0 GB   |
  | `xp`   | Windows XP Professional   | 0.6 GB   |
  | `2k`   | Windows 2000 Professional | 0.4 GB   | 
  ||||  
  | `2025` | Windows Server 2025       | 5.6 GB   |
  | `2022` | Windows Server 2022       | 4.7 GB   |
  | `2019` | Windows Server 2019       | 5.3 GB   |
  | `2016` | Windows Server 2016       | 6.5 GB   |
  | `2012` | Windows Server 2012       | 4.3 GB   |
  | `2008` | Windows Server 2008       | 3.0 GB   |
  | `2003` | Windows Server 2003       | 0.6 GB   |

> [!TIP]
> To install ARM64 versions of Windows use [dockur/windows-arm](https://github.com/dockur/windows-arm/).

### How do I change the storage location?

  To change the storage location, include the following bind mount in your compose file:

  ```yaml
  volumes:
    - ./windows:/storage
  ```

  Replace the example path `./windows` with the desired storage folder or named volume.

### How do I change the size of the disk?

  To expand the default size of 64 GB, add the `DISK_SIZE` setting to your compose file and set it to your preferred capacity:

  ```yaml
  environment:
    DISK_SIZE: "256G"
  ```
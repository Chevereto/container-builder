# Persistent storage

## Using Volumes

If you are using volumes for persistent storage, permissions in the mount path must be `www-data:www-data` to enable Chevereto to write those volumes.

Run this command in the Chevereto container to set the right permissions:

```sh
/bin/bash -c 'chown -R www-data: images/ importing/'
```

## Permissions check

Enter to the container console `/bin/bash`. Once there, run `ls -la` to list the file system. You should see something like this:

```plain
www-data@20d1427c6727:~/html$ ls -la
total 52
drwxrwxrwx  8 www-data www-data 4096 Apr  1 18:56 .
drwxr-xr-x  1 root     root     4096 Mar 29 01:50 ..
-rw-r--r--  1 www-data www-data    0 Aug  2  2021 .gitkeep
-rw-r--r--  1 www-data www-data 1342 Mar 21 20:26 .htaccess
-rw-r--r--  1 www-data www-data 6009 Mar 21 20:26 LICENSE
drwxr-xr-x 11 www-data www-data 4096 Apr  1 18:55 app
drwxr-xr-x  5 www-data www-data 4096 Apr  1 18:56 content
drwxr-xr-x  3 www-data www-data 4096 Apr  1 18:53 images
drwxr-xr-x  5 www-data www-data 4096 Apr  1 18:56 importing
-rw-r--r--  1 www-data www-data  290 Mar 21 20:26 index.php
drwxr-xr-x  2 www-data www-data 4096 Apr  1 18:56 sdk
```

## Volume reference

| Volume                         | Mount path            | Purpose                                     |
| ------------------------------ | --------------------- | ------------------------------------------- |
| [Chevereto volume](#chevereto) | /var/www/html/        | Chevereto application files                 |
| [Storage volume](#storage)     | /var/www/html/images/ | User uploads + assets (avatars, logos, etc) |

### Chevereto

This volume is for storing the application files shared between containers `php` and `http`.

👉 This keep the application files shared between containers.

### Storage

This volume is for storing user uploaded images and assets namely user avatars, website logos, background images, etc.

👉 This is used when you don't add any External storage provider to Chevereto.

## Using external services

Chevereto supports external storage providers for user generated content and website assets. It support any mixture of configurations as you may need to customize. Refer to the following reference for more information on service providers for storage:

* [External storage](https://v4-admin.chevereto.com/features/external-storage.html) documentation
* Assets storage (work in progress)

## Troubleshoot

### No persistence

The compose project name could be altered due to a change in `NAMESPACE`, `TARGET`. If this happens, do the following:

1. Run `docker volume ls` and locate the volumes used by your project
2. Run `make feedback--volumes` to determine the volumes in the current context
3. For **each volume**, [copy](VOLUMES.md#volume-copy) from the volume (1) to (2):

```sh
make volume-cp VOLUME_FROM=<from_volume> VOLUME_TO=<to_volume>
```

For example:

```sh
make volume-cp VOLUME_FROM=local_chevereto-build_database VOLUME_TO=chevereto_chevereto_database
make volume-cp VOLUME_FROM=local_chevereto-build_storage VOLUME_TO=chevereto_chevereto_storage
```

After that, [restart](DOCKER-COMPOSE.md#restart) containers:

```sh
make restart
```

If everything went well the system will reflect the existing persistance layer, from there you can [remove](VOLUMES.md#volume-remove) the old volumes from (1):

```sh
make volume-rm local_chevereto-build_database
make volume-rm local_chevereto-build_storage
```

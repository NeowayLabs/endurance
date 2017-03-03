import klb/azure/nic
import klb/azure/subnet
import klb/azure/vm
import klb/azure/public-ip
import klb/azure/availset
import klb/azure/storage
import klb/azure/disk
import resources/lib/map

# The configuration is azure/lib/map
fn resources_lib_vm_create(cfg) {
	resgroup       <= resources_lib_map_get($cfg, "resgroup")
	location       <= resources_lib_map_get($cfg, "location")
	public_ip_name <= resources_lib_map_get($cfg, "public_ip_name")

	if len($public_ip_name) != "0" {
		public_ip_name = $resgroup+"-"+$public_ip_name
		
		azure_public_ip_create($public_ip_name, $resgroup, $location, "Static")
	}

	availset        <= resources_lib_map_get($cfg, "availset")
	availset_exists <= azure_availset_exists($availset, $resgroup)

	if $availset_exists == "false" {
		echo "there is no availset: "+$availset
		echo "creating"
		
		azure_availset_create($availset, $resgroup, $location)
	}

	nicname <= resources_lib_map_get($cfg, "nicname")

	nicname = $resgroup+"-"+$nicname

	nic             <= azure_nic_new($nicname, $resgroup, $location)
	vnet            <= resources_lib_map_get($cfg, "vnet")
	subnet          <= resources_lib_map_get($cfg, "subnet")
	subnet_resgroup <= resources_lib_map_get($cfg, "subnet_resgroup")

	if len($subnet_resgroup) != "0" {
		echo "subnet is not on the same resource group, getting ID"
		
		subnet_id <= azure_subnet_get_id($subnet, $subnet_resgroup, $vnet)
		
		echo "got subnet id: "+$subnet_id
		
		nic <= azure_nic_set_subnet_id($nic, $subnet_id)
	} else {
		echo "subnet on same resource group setting 'vnet' and 'subnet' parameters"
		
		nic <= azure_nic_set_vnet($nic, $vnet)
		nic <= azure_nic_set_subnet($nic, $subnet)
	}

	ipfw <= resources_lib_map_get($cfg, "ipfw")

	if len($ipfw) != "0" {
		nic <= azure_nic_set_ipfw($nic, $ipfw)
	}
	if len($public_ip_name) != "0" {
		nic <= azure_nic_set_publicip($nic, $public_ip_name)
	}

	private_ip <= resources_lib_map_get($cfg, "private_ip")

	if len($private_ip) != "0" {
		nic <= azure_nic_set_privateip($nic, $private_ip)
	}

	azure_nic_create($nic)

	## VM
	name <= resources_lib_map_get($cfg, "name")

	name = $resgroup+"-"+$name

	vm           <= azure_vm_new($name, $resgroup, $location, "Linux")
	boot_storage <= resources_lib_map_get($cfg, "boot_storage")

	if len($boot_storage) != "0" {
		boot_storage <= azure_storage_account_create($boot_storage, $resgroup, $location, "LRS", "Storage")
		vm           <= azure_vm_set_bootdiagnosticsstorage($vm, $boot_storage)
	}

	size         <= resources_lib_map_get($cfg, "size")
	vm           <= azure_vm_set_vmsize($vm, $size)
	username     <= resources_lib_map_get($cfg, "username")
	vm           <= azure_vm_set_username($vm, $username)
	availset     <= resources_lib_map_get($cfg, "availset")
	vm           <= azure_vm_set_availset($vm, $availset)
	vm           <= azure_vm_set_vnet($vm, $vnet)
	vm           <= azure_vm_set_subnet($vm, $subnet)
	vm           <= azure_vm_set_nic($vm, $nicname)
	storage_type <= resources_lib_map_get($cfg, "storage_type")

	if len($storage_type) == "0" {
		storage_type = "LRS"
	}

	storage_account_name <= resources_lib_map_get($cfg, "storage_account")
	stracc_vm            <= azure_storage_account_create($storage_account_name, $resgroup, $location, $storage_type, "Storage")
	vm                   <= azure_vm_set_storageaccount($vm, $stracc_vm)
	diskname             <= resources_lib_map_get($cfg, "diskname")

	diskname             = $resgroup+"-"+$diskname

	vm                   <= azure_vm_set_osdiskvhd($vm, $diskname)
	image_urn            <= resources_lib_map_get($cfg, "image_urn")
	vm                   <= azure_vm_set_imageurn($vm, $image_urn)
	customdata           <= resources_lib_map_get($cfg, "customdata")
	vm                   <= azure_vm_set_customdata($vm, $customdata)
	accesskey            <= resources_lib_map_get($cfg, "accesskey")
	vm                   <= azure_vm_set_publickeyfile($vm, $accesskey)

	azure_vm_create($vm)

	disks <= resources_lib_map_get($cfg, "disks")

	if len($disks) != "0" {
		for disk in $disks {
			disk_size = $disk[0]
		
			sequence <= seq 1 $disk[1]
			range    <= split($sequence, "\n")
		
			for disk_number in $range {
				storacc_disk <= azure_storage_account_create($storage_account_name+$disk_number, $resgroup, $location, $storage_type, "Storage")
		
				disk_name = "disk-"+$disk_size+"-"+$disk_number
		
				azure_disk_attach_new($resgroup, $name, $storacc_disk, $disk_size, $disk_name)
			}
		}
	}
}

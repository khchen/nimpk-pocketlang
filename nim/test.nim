import pk
import pkfiles

var vm = pkNewVM(nil)
# vm.pkReserveSlots(0)
echo vm.pkImportModule("ttttt", 0)

var m = vm.pkNewModule("ttttt")
vm.pkRegisterModule(m)
echo vm.pkImportModule("ttttt", 0)


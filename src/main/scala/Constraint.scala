

// A constrain tells if a certain package with at least a particular version needs to be installed or removed.
class Constraint(val install: Boolean, val packageName : String, val version: String){
}

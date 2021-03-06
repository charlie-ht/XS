fn %max {|*|
	# Return the largest of a list.
	let (f; (m r) = $*) {
		while {!~ $r ()} {
			(f r) = $r
			{$f :gt $m} && {m = $f}
		}
		result $m
	}
}

fn %min {|*|
	# Return the smallest of a list.
	let (f; (m r) = $*) {
		while {!~ $r ()} {
			(f r) = $r
			{$f :lt $m} && {m = $f}
		}
		result $m
	}
}

fn %range {|*|
	# Given a comma-separated list of counting numbers and ranges, where
	# a range is delimited with -, return a sorted list of integers.
	# The order of a range's endpoints does not matter.
	let (f; r = $*; l) {
		while {!~ $r ()} {
			if {~ $r *,*} {(f r) = <={~~ $r *,*}} else {(f r) = $r}
			if {~ $f *-*} {
				(a b) = <={~~ $f *-*}
				{$a :gt $b} && {(a b) = $b $a}
				let (n = $a; s = `($b + 1)) {
					while {!~ $n $s} {
						l = $l $n
						n = `($n + 1)
					}
				}
			} else {
				l = $l $f
			}
		}
		result `{echo $l|tr ' ' \n|sort -n}
	}
}

fn %list {|*|
	# Given a comma-separated list of tokens, return a list of tokens.
	let (f; r = $*; l) {
		while {!~ $r ()} {
			if {~ $r *,*} {(f r) = <={~~ $r *,*}} else {(f r) = $r}
			l = $l $f
		}
		result $l
	}
}

fn %args {|*|
	# Given a list of command-line arguments where the list contains N
	# elements, return a 2N-element list where each pair of elements
	# corresponds to one element of the argument. The first element of
	# each pair is always an option flag; the second is always a non-
	# option argument. The absence of a flag or argument is denoted by
	# _ in the result list. Tokens following a -- option are all treated
	# as arguments, even in the case where a token begins with -.
	let (r = $*; l) {
		while {!~ $r ()} {
			let (f; m = '_') {
				(f r) = $r
				if {~ $f --} {
					l = $l $f $m
					while {!~ $r ()} {
						(f r) = $r
						l = $l $m $f
					}
				} else if {~ $f -*} {
					let ((a b) = $r) {
						if {~ $a -*} {
							l = $l $f $m
						} else {
							{~ $a ()} && a = $m
							l = $l $f $a
							r = $b
						}
					}
				} else {
					l = $l $m $f
				}
			}
		}
		result $l
	}
}

fn %parse-args {|*|
	# Given the output of $args followed by \& and a list of option/
	# thunk pairs to be used for processing options, process the
	# options and a return a list of the non-option words optionally
	# followed by -- and following words. Within the option thunks,
	# the option and its value are denoted $optopt and $optval.
	let (a) {
		let (l = $*) {
			{escape {|fn-break| while {!~ $l ()} {
				(o v l) = $l
				{~ $o \&} && {l = $v $l; break}
				a = $a $o $v
			}}}
			cases = $l
		}
		let (l = $a; words; extra) {
			while {!~ $l ()} {
				(optopt optval l) = $l
				if {~ $extra(1) --} {extra = $extra $optval} \
				else switch $optopt (
					_ {words = $words $optval}
					-- {extra = $optopt}
					$cases
					{throw error %parse-args \
						'opt? '^$optopt}
				)
			}
			result $words $extra
		}
	}
}

fn %argify {|*|
	# Always return a one-element list
	if {~ $* ()} {result ''} else {result `` '' {echo -n $*}}
}

fn %with-quit {|*|
	# Run command with q key bound to send SIGINTR.
	stty intr q
	unwind-protect {
		$*
	} {
		stty intr \^C
	}
}

fn %without-cursor {|*|
	# Run command with terminal cursor hidden.
	.ci
	unwind-protect {
		$*
	} {
		.cn
	}
}

fn %with-tempfile {|name body|
	local ($name = `mktemp) {
		unwind-protect {
			$body
		} {
			rm -f $name
		}
	}
}

fn %aset {|n i v|
	# Emulate indexed assignment.
	\xff^$n[$i] = $v
}

fn %aref {|n i|
	# Emulate indexed retrieval.
	result $(\xff^$n[$i])
}

let (g = 0) {
	fn %gensym {
	# Generate a "unique" name.
		let (n = \xff\xff^`{printf G%04u $g}) {
			g = `($g+1)
			result $n
		}
	}
}

fn %with-read-lines {|file body|
	# Run body with each line from file.
	# Body must be a lambda; its argument is bound to the line content.
	<$file let (__l = <=read) {
		while {!~ $__l ()} {
			$body $__l
			__l = <=read
		}
	}
}

fn %with-read-chars {|line body|
	# Run body with each character from line.
	# Body must be a lambda; its argument is bound to the next character.
	let (i = 0; lc = <={%fsplit '' $line}) {
		let (ll = $#lc; __c) {
			let (fn-nextc = {
				i = `($i+1)
				if {$i :le $ll} {
					result <={__c = $lc($i)}
				} else {
					result <={__c = ()}
				}}) {
				while {!~ <=nextc ()} {
					$body $__c
				}
			}
		}
	}
}

fn %pprint {|fn-name|
	# Pretty print named function
	~ $(fn-$fn-name) () && {throw error %pprint 'not a function'}
	printf fn\ %s $fn-name
	let (depth = 1; q = 0) {
		let ( \
			fn-wrap = {
				printf %c\n '\'
				for i `{seq `($depth*4)} {printf ' '}
			} \
			) {
			%with-read-chars $(fn-$fn-name) {|c|
				~ $c '''' && {q = `(($q+1)%2)}
				~ $q 0 && switch $c (
				'{'	{wrap; depth = `($depth+1)}
				'}'	{depth = `($depth-1)}
				'^'	{wrap}
				)
				printf %c $c
			}
		}
	}
	printf \n
}

fn %id {|*|
	# Without an arg, return a five-element list:
	#   name version date hash repository-url
	# With an arg, return the index'th item(s).
	let (info = xs <={~~ <=$&version 'xs '*' (git: '*'; '*' @ '*')'}) {
		if {~ $#* 0} {
			result $info
		} else {
			result $info($*)
		}
	}
}

fn %mkobj {
	# Create an object; return its name
	let (nm = go; go = go) {
		while {!~ $($nm) ()} {nm = \xff^objid:^<=$&random}
		$nm = obj
		result $nm
	}
}

fn .objcheck {|objname|
	# Throw an error if objname does not name an object
	if {{~ $objname ()} || {!~ $($objname) obj *\ obj}} {
		throw error object 'Not an object: '^$objname
	}
}

fn %objset {|objname key value|
	# Set an object field
	.objcheck $objname
	%objunset $objname $key
	$objname = $key:$value $($objname)
}

fn %objunset {|objname key|
	# Remove an object field
	.objcheck $objname
	let (ov = $($objname); rv) {
		for kv $ov {
			{!~ $kv $key:*} && {rv = $rv $kv}
		}
		$objname = $rv
	}
}

fn %objget {|objname key default|
	# Get an object field
	.objcheck $objname
	let (v = <={~~ $($objname) $key:*}) {
		if {!~ $v ()} {result $v} else {result $default}
	}
}

fn %obj-isempty {|objname|
	# True if object has no fields
	.objcheck $objname
	result <={!~ $($objname) *:*}
}

fn %objreset {|objname|
	# Remove all fields from an object
	.objcheck $objname
	$objname = obj
}

fn %mkdict {|*|
	# Make a dictionary from a list of key/value pairs
	let (d = <=%mkobj) {
		while {!~ $* ()} {
			(k v) = $*(1 2)
			* = $*(3 ...)
			%objset $d $k $v
		}
		result $d
	}
}

fn %asort {
	# Sort by length, then by name
	%with-read-lines /dev/stdin {|line|
		let (len = <={$&len $line}) {
			printf %06d%s\n $len $line
		}
	} | sort | cut -c7-
}

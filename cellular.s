########################################################################
# COMP1521 20T2 --- assignment 1: a cellular automaton renderer
#
# Written by <<Z5311917>>, July 2020.

# Maximum and minimum values for the 3 parameters.

MIN_WORLD_SIZE	=    1
MAX_WORLD_SIZE	=  128
MIN_GENERATIONS	= -256
MAX_GENERATIONS	=  256
MIN_RULE	=    0
MAX_RULE	=  255

# Characters used to print alive/dead cells.

ALIVE_CHAR	= '#'
DEAD_CHAR	= '.'

# Maximum number of bytes needs to store all generations of cells.

MAX_CELLS_BYTES	= (MAX_GENERATIONS + 1) * MAX_WORLD_SIZE

	.data

cells:	.space MAX_CELLS_BYTES

# Strings

prompt_world_size:	.asciiz "Enter world size: "
error_world_size:	.asciiz "Invalid world size\n"
prompt_rule:		.asciiz "Enter rule: "
error_rule:		.asciiz "Invalid rule\n"
prompt_n_generations:	.asciiz "Enter how many generations: "
error_n_generations:	.asciiz "Invalid number of generations\n"

#.TEXT <main>
	        .text
# Registers used: 
        # $a0, $a1, $a2, $s0, $s1, $s2, $s3, $s4, $s0, $v0, $ra, $t0, $t2, $t3
# Registers with different values after run generation:
        # $t1, $t2, $t4, $t6, $t7, $t0 

# Locals:
#       - 'world_size' in $s0
#       - 'rule' in $s1
#       - 'n_generations' in $s2
#       - 'reverse' in $s3
#       - iterators in $s4
#       - $t? registers used for calculations

main:  

get_world_size:	
	    la      $a0, prompt_world_size
	    li      $v0, 4
        syscall                         
        li      $v0, 5          
        syscall
        bgt     $v0, MAX_WORLD_SIZE, invalid_world_size 
        blt     $v0, MIN_WORLD_SIZE, invalid_world_size       
        move    $s0, $v0                # Store world size in $s0         
        
get_rule:        
        la      $a0, prompt_rule
	    li      $v0, 4
        syscall    
        li      $v0, 5          
        syscall
        bgt     $v0, MAX_RULE, invalid_rule
        blt     $v0, MIN_RULE, invalid_rule
        move    $s1, $v0                # Store rule in $s1 
                
get_n_generation:        
        la      $a0, prompt_n_generations
	    li      $v0, 4
        syscall    
        li      $v0, 5         
        syscall
        bgt     $v0, MAX_GENERATIONS, invalid_n_generations
        blt     $v0, MIN_GENERATIONS, invalid_n_generations
        move    $s2, $v0                # Store n_generations in $s2          
        li      $a0, '\n'     
        li      $v0, 11
        syscall
        
check_negative_generations:        
        li      $s3, 0                  # Negative generations means show 
        blt     $s2, 0, reversed        # the generations in reverse
                                        # if (n_generations < 0) {        
first_generation:        
        la      $t0, cells              # Load start of array into $t0          
        div     $t2, $s0, 2             # Find middle of world
        add     $t0, $t0, $t2           # Calculate byte offset
        li      $t3, 1
        sb      $t3, ($t0)              # Store alive cell in middle of world
                                        
loop_generations_init:        
        li      $s4, 1                  # int g = 1
loop_generations_cond:
        bgt     $s4, $s2, loop_generations_end
        move    $a0, $s0                # Move world size into $a0
        move    $a1, $s1                # Move rule into $a1
        move    $a2, $s4                # Move g into $a2
        sub     $sp, $sp, 4             # Move stack pointer down to make room
        sw      $ra, 0($sp)             # Save $ra on $stack        
        jal run_generation              # Run run_generation
        lw      $ra, 0($sp)             # Restore stack pointer            
        add     $sp, $sp, 4             # Move stack pointer back to normal
loop_generations_step:         
        addi    $s4, 1                  # g++
        b       loop_generations_cond   
        
loop_generations_end:

check_print_reversed:
        beq     $s3, 1, loop_print_reversed     # if (reversed) { goto loop_print_reversed
                                                # else { print loop normal
loop_print_init: 
        li      $s4, 0                          # int g = 1                          
loop_print_cond:
        bgt     $s4, $s2, loop_print_end        # while (g <= n_generations) {   
        
        sub     $sp, $sp, 4             # Move stack pointer down to make room
        sw      $ra, 0($sp)             # Save $ra on $stack
        
        move    $a0, $s0                # Move world_size into $a0
        move    $a1, $s4                # Move g into $a1
        jal print_generation            # Run print_generation
        
        lw      $ra, 0($sp)             # Restore $ra on $stack
        add     $sp, $sp, 4             # Move stack pointer back
                
loop_print_step:
        addi    $s4, 1                  # g++
        b       loop_print_cond
loop_print_end:
		
end_of_program:
	    li	$v0, 0                  # return 0
	    jr	$ra
	
############
   
loop_print_reversed:

loop_print_reversed_init: 
        move    $s4, $s2                # int g = -n_generations
loop_print_reversed_cond:
        blt     $s4, 0, loop_print_reversed_end  # while (g >= 0) {
        sub     $sp, $sp, 4             # Move stack pointer down to make room
        sw      $ra, 0($sp)             # Save $ra on $stack       
        move    $a0, $s0                # Move world_size into $a0
        move    $a1, $s4                # Move g into $a1
        jal     print_generation        # Run print_generation
        lw      $ra, 0($sp)             # Restore $ra on $stack
        add     $sp, $sp, 4             # Move stack pointer back

loop_print_reversed_step:
        addi    $s4, -1                 # g--
        b       loop_print_reversed_cond

loop_print_reversed_end:
        b       end_of_program
        
invalid_world_size:
        la      $a0, error_world_size
        li      $v0, 4
        syscall                         # print("Invalid world size")
        li	$v0, 1
        jr	$ra
        
invalid_rule:
        la      $a0, error_rule
        li      $v0, 4
        syscall                         # print("Invalid rule")
        li	$v0, 1
        jr	$ra
         
invalid_n_generations:
        la      $a0, error_n_generations
        li      $v0, 4
        syscall                         # print("Invalid number of generations")
        li	$v0, 1
        jr	$ra
        
reversed:
        li      $s3, 1                  # reversed = 1
        mul     $s2, $s2, -1            # n_generations = -n_generations
        b       first_generation        # goto first_generation

######################################################################
#.TEXT <run_generation>	
	# Given `world_size', `which_generation', and `rule', calculate
	# a new generation according to `rule' and store it in `cells'.
	
# Registers used: 
        # $sp, $s1, $s2, $s3, $s4, $s5, $a0, $a1, $a2, $t1, 
        # $t2, $t4, $t6, $t7, $t0, $ra 
        
# Registers with different values after print generation:
        # $a0, $a1, $t0, $t1, $t4	
        
# Locals:
#       -  iterators in $t0
#       - 'world size' in $a0   
#       - 'rule' in $a1
#       - 'which generation' in $a2
#       - 'left' in $s1
#       - 'centre' in $s2
#       - 'right' in $s3
#       - 'state' in $s4
#       - 'set' in $s5
#       - $t? registers used for calculations
run_generation:
        sub     $sp, $sp, 20
        sw      $s5, 16($sp)    
        sw      $s4, 12($sp)    
        sw      $s3, 8($sp)             # Save $s? registers to stack
        sw      $s2, 4($sp)    
        sw      $s1, 0($sp)     
        
run_generation_i_init:  
        li      $t0, 0                  # int i = 0
        
run_generation_i_cond:
        bge     $t0, $a0, run_generation_i_false                # while (i < world_size)
        
left:
        li      $s1, 0                  # int left = 0
        ble     $t0, 0, centre          # if (i > 0)        
        la      $t1, cells              # Load array starting address                              
        sub     $t2, $a2, 1             # which_generation - 1
        mul     $t4, $t2, $a0           # multiply world_size with which_generation - 1           
        add     $t1, $t1, $t4           # Add row offset to starting address of array                                             
        add     $t1, $t1, $t0           # Add column offset]
        lb      $s1, -1($t1)            # left = cells[which_generation - 1][x - 1]                
        
centre:
        la      $t1, cells              # Load array starting address   
        sub     $t2, $a2, 1             # which_generation - 1
        mul     $t4, $t2, $a0           # multiply world_size with which_generation - 1    
        add     $t1, $t1, $t4           # Add row offset to starting address of array    
        add     $t1, $t1, $t0           # Add column offset                                       
        lb      $s2, ($t1)              # int centre = [which_generation-1][x] 
right:
        li      $s3, 0                  # int right = 0
        add     $t1, $a0, -1            # Calculate world_size - 1
        bge     $t0, $t1, convert_states        # if (i < world_size - 1)       
        la      $t1, cells              # Load array starting address
        sub     $t2, $a2, 1             # which_generation - 1
        mul     $t4, $t2, $a0           # multiply world_size with which_generation - 1   
        add     $t1, $t1, $t4           # Add row offset to starting address of array       
        add     $t1, $t1, $t0           # Add column offset 
        lb      $s3, 1($t1)             # right = cells[which_generation - 1][x + 1]             
        
convert_states:
        sll     $t1, $s1, 2             # $t1 = left << 2
        sll     $t2, $s2, 1             # $t2 = centre << 1
        sll     $t3, $s3, 0              # $t3 = right << 0
        or      $s4, $t1, $t2           # state = state | left
        or      $s4, $s4, $t3           # state = state | centre
             
check_bit_rule:
        li      $t7, 1                  # int bit = 1
        sllv    $t1, $t7, $s4           # bit = 1 << state
        and     $s5, $a1, $t1           # set = rule & bit
        beq     $s5, 0, check_bit_rule_false    # if (set) {
        la      $t1, cells              # Load array starting address      
        mul     $t4, $a2, $a0           # multiply world_size with which_generation  
        add     $t1, $t1, $t4           # Add row offset to starting address of array    
        add     $t1, $t1, $t0           # Add column offset 
        li      $t6, 1                                 
        sb      $t6, ($t1)              # cells[which_generation][x] = 1        
        b       run_generation_i_step   # goto run_generation_i_step
        
check_bit_rule_false:

        la      $t1, cells              # Load array starting address        
        mul     $t4, $a2, $a0           # multiply world_size with which_generation 
        add     $t1, $t1, $t4           # Add row offset to starting address of array    
        add     $t1, $t1, $t0           # Add column offset 
        li      $t6, 0                                 
        sb      $t6, ($t1)              # cells[which_generation][x] = 0            
run_generation_i_step:
        addi    $t0, 1                  # i++
        b       run_generation_i_cond   
run_generation_i_false:

run_generation__epi:  
     
	    lw      $s5, 16($sp)    
        lw      $s4, 12($sp)    
        lw      $s3, 8($sp)             # restore $s? registers
        lw      $s2, 4($sp)    
        lw      $s1, 0($sp)
        add     $sp, $sp, 20            # move stack pointer back
        
	    jr	$ra                     # return to main

#####################################################################
#TEXT <print_generation>

	# Given `world_size', and `which_generation', print out the
	# specified generation.
	
# Registers used: 
        # $sp, $s1, $s2, $a0, $a1, $t0, $t1, $t4, $v0 
        
# Locals:
#       - world size in $s0
#       - which generation in $s1
#       - cells [which_generation][x] in $s2
#       - $t? registers used for calculations
print_generation:

        sub     $sp, $sp, 12            # Move stack pointer down
        sw      $s2, 8($sp)    
        sw      $s1, 4($sp)             # Save $s? registers to stack
        sw      $s0, 0($sp)    
	    move    $s0, $a0                # Move world size to $s0
	    move    $s1, $a1                # Move which_generation to $s1
	
	    move    $a0, $s1
	    li      $v0, 1                  # print which generation
	    syscall	
	    li      $a0, '\t'               # printf("%c", '\t');
        li      $v0, 11
        syscall	
print_generation_x_init:
	
	    li      $t0, 0                  # int x = 0
print_generation_x_cond:

        bge     $t0, $s0, print_generation_x_false      # while (x < world_size) {
        la      $t1, cells              # load start of array
        mul     $t4, $s1, $s0           # multiply world_size with which_generation 
        add     $t1, $t1, $t4           # Add row offset to starting address of array       
        add     $t1, $t1, $t0           # Add column offset 
        lb      $s2, ($t1)              # Store value of cells[which_generation][x] in $s2
        
if_cells_alive:

        beq     $s2, 0, if_cells_dead   # if (cells[which_generation][x]) {
        li      $a0, ALIVE_CHAR         # printf("%c", 'ALIVE_CHAR')
        li      $v0, 11
        syscall       
        b       print_generation_x_step # goto print_generation_x_step
        
if_cells_dead:

        li      $a0, DEAD_CHAR          # printf("%c", 'DEAD_CHAR')
        li      $v0, 11
        syscall      
        b       print_generation_x_step # goto print_generation_x_step
print_generation_x_step:

        addi    $t0, 1                  # x++
        b       print_generation_x_cond # goto print_generation_x_cond
print_generation_x_false:
        
        li      $a0, '\n'               # printf("%c", '\n')
        li      $v0, 11
        syscall
print_generation_x_epi:

        lw      $s2, 8($sp)     
        lw      $s1, 4($sp)             # Restore $s? registers              
        lw      $s0, 0($sp)     
        add     $sp, $sp, 12            # Move stack pointer back
	    jr	$ra                     # goto main

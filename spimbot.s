# syscall constants
PRINT_STRING = 4
PRINT_CHAR   = 11
PRINT_INT    = 1

# debug constants
PRINT_INT_ADDR   = 0xffff0080
PRINT_FLOAT_ADDR = 0xffff0084
PRINT_HEX_ADDR   = 0xffff0088

# spimbot constants
VELOCITY       = 0xffff0010
ANGLE          = 0xffff0014
ANGLE_CONTROL  = 0xffff0018
BOT_X          = 0xffff0020
BOT_Y          = 0xffff0024
OTHER_BOT_X    = 0xffff00a0
OTHER_BOT_Y    = 0xffff00a4
TIMER          = 0xffff001c
SCORES_REQUEST = 0xffff1018

TILE_SCAN       = 0xffff0024
SEED_TILE       = 0xffff0054
WATER_TILE      = 0xffff002c
MAX_GROWTH_TILE = 0xffff0030
HARVEST_TILE    = 0xffff0020
BURN_TILE       = 0xffff0058
GET_FIRE_LOC    = 0xffff0028
PUT_OUT_FIRE    = 0xffff0040

GET_NUM_WATER_DROPS   = 0xffff0044
GET_NUM_SEEDS         = 0xffff0048
GET_NUM_FIRE_STARTERS = 0xffff004c
SET_RESOURCE_TYPE     = 0xffff00dc
REQUEST_PUZZLE        = 0xffff00d0
SUBMIT_SOLUTION       = 0xffff00d4

# interrupt constants
BONK_MASK               = 0x1000
BONK_ACK                = 0xffff0060
TIMER_MASK              = 0x8000
TIMER_ACK               = 0xffff006c
ON_FIRE_MASK            = 0x400
ON_FIRE_ACK             = 0xffff0050
MAX_GROWTH_ACK          = 0xffff005c
MAX_GROWTH_INT_MASK     = 0x2000
REQUEST_PUZZLE_ACK      = 0xffff00d8
REQUEST_PUZZLE_INT_MASK = 0x800

.data
# data things go here
.align 2
tiles: .space 16 * 100
puzzle_data: .space 4096
solution_data: .space 328
request_puzzle_on: .word 0
counter: .word 1
next_request: .word 0
max_growth_on: .word 0
max_growth_loc: .word 0 
bonk_on: .word 0
harvesting: .word 0

.text

main:


  # lw    $a0, counter
  # jal   move_checkerboard 
  # add   $a0, $a0, 1
  # sw    $a0, counter

  li     $t4, TIMER_MASK    # timer interrupt enable bit
  or     $t4, $t4, BONK_MASK  # bonk interrupt bit
  # or     $t4, $t4, ON_FIRE_MASK 
  or     $t4, $t4, MAX_GROWTH_INT_MASK
  or     $t4, $t4, REQUEST_PUZZLE_INT_MASK
  or     $t4, $t4, 1    # global interrupt enable
  mtc0   $t4, $12   # set interrupt mask (Status register)



	lw 		$a0, BOT_X($0)
	li 		$a1, 15 
	jal 	moveToX

	lw 		$a0, BOT_Y($0)
	li 		$a1, 285
	jal 	moveToY	

  #sw    $t1, SEED_TILE

infinite:
#   lw    $t3, harvesting
#   beq   $t3, 0, plant_seeds
#   j     harvest

# harvest:
#   lw    $t3, max_growth_on
#   beq   $t3, 0, plant_seeds

#   lw    $a0, max_growth_loc

#   la    $t0, tiles
#   sw    $t0, TILE_SCAN 

#   lw    $a0, BOT_X
#   lw    $a1, BOT_Y 
#   jal   get_index
#   move  $t2, $v0                      #index of current bot 

#   mul   $t2, $t2, 16
#   add   $t3, $t0, $t2
#   lw    $t4, 0($t3)
#   beq   $t4, 0, move_next_tile           #check if the tile already has a plant
#   lw    $t4, 4($t3)
#   beq   $t4, 1, move_next_tile           #check if tile is owned by our bot
#   #put a fire if not owned by our bot 


#   sw    $0, HARVEST_TILE


#   j     move_next_tile


  # lw    $t0, max_growth_on
  # beq   $t0, 0, plant_seeds
  # lw    $a0, max_growth_loc
  # jal   harvest_tile



plant_seeds:

	lw 		$t1, GET_NUM_SEEDS
	bne 	$t1, 0, have_seeds



waiting_seeds:
  li    $a0, 1
  lw    $t0, request_puzzle_on
  beq   $t0, 1, waiting_seeds

  jal   request_and_solve
  lw    $t1, GET_NUM_SEEDS

have_seeds:
	la    $t0, tiles
  sw    $t0, TILE_SCAN 

  lw 		$a0, BOT_X
	lw 		$a1, BOT_Y 
	jal 	get_index
	move 	$t2, $v0                      #index of current bot 

	mul 	$t2, $t2, 16
	add 	$t3, $t0, $t2
  lw    $t4, 4($t3)
  beq   $t4, 1, burn_tile           #check if tile is owned by our bot
	lw 		$t4, 0($t3)
	beq 	$t4, 1, move_next_tile           #check if the tile already has a plant

	sw 		$t1, SEED_TILE
  j     move_next_tile

burn_tile:

  lw    $t1, GET_NUM_FIRE_STARTERS
  bne   $t1, 0, burn_the_tile
  li    $t2, 2
  move  $a0, $t2
  jal   request_and_solve

burn_the_tile:
  sw    $t0, BURN_TILE

 move_next_tile:

  #lw    $a0, next_request
  # lw    $t0, request_puzzle_on
  # beq   $t0, 1, no_request

  # li    $a0, 0
  # jal   request_puzzle  

  lw    $a0, counter
  jal   move_checkerboard
  lw    $a0, counter 

 
  beq   $a0, $0, harvest

  add   $a0, $a0, 1
  sw    $a0, counter

  lw    $t5, next_request
  not   $t5, $t5
  sw    $t5, next_request


  j     infinite

harvest:
  lw    $t3, max_growth_on
  beq   $t3, 0, harvest

  li    $t0, 1
  sw    $t0, counter
  j     keep_harvesting

harvest_loop: 
  lw    $t0, counter
  beq   $t0, 1, plant_more_seeds

  lw    $t1, counter 
  bne   $t1, $0, keep_harvesting
  add   $t1, $t1, 1 
  sw    $t1, counter
  j     plant_seeds

 keep_harvesting:
  la    $t0, tiles
  sw    $t0, TILE_SCAN 

  lw    $a0, BOT_X
  lw    $a1, BOT_Y 
  jal   get_index
  move  $t6, $v0                      #index of current bot 

  mul   $t2, $t6, 16
  add   $t3, $t0, $t2
  lw    $t4, 0($t3)
  beq   $t4, 0, move_next          #check if the tile already has a plant
  lw    $t4, 4($t3)
  beq   $t4, 1, move_next           #check if tile is owned by our bot
  
  #put a fire if not owned by our bot 

  sw    $0, HARVEST_TILE

 move_next:
  jal   move_next_tile_fn

  j     harvest_loop

#   j     infinite 

  # lw    $t0, request_puzzle_on
  # beq   $t0, 1, solve_puzzle
 plant_more_seeds:

   sw     $0, counter
 keep_on_planting:

  lw     $t0, counter
  add    $t0, $t0, 1
  sw     $t0, counter

  lw      $t0, counter
  beq     $t0, 10, harvest_more

  la      $t0, tiles
  sw      $t0, TILE_SCAN 

  lw      $a0, BOT_X
  lw      $a1, BOT_Y 
  jal     get_index
  move    $t6, $v0                     #index of current bot 

  mul     $t2, $t6, 16
  add     $t3, $t0, $t2
  lw      $t4, 0($t3)
  beq     $t4, 1, keep_on_planting    #check if the tile already has a plant

   lw     $t2, GET_NUM_SEEDS
   bne    $t2, 0, continue_planting
   li     $a0, 1
   jal    request_and_solve 

 continue_planting:
   sw     $t1, SEED_TILE
   lw     $a0, BOT_X
   add    $a1, $a0, 30
   jal    moveToX
   # lw     $t0, counter
   # add    $t0, $t0, 1
   # sw     $t0, counter
   j      keep_on_planting

harvest_more:
   lw    $a0, BOT_X
   li    $a1, 15
   jal   moveToX

 # waiting:
 #    sw    $t2, TIMER
 #    bge   $t2, , waiting
skip_harvest:
   sw    $a0, BOT_X
   add   $a1, $a0, 30
   jal   moveToX

harvesting_cont:
  la    $t0, tiles
  sw    $t0, TILE_SCAN 

  lw    $a0, BOT_X
  lw    $a1, BOT_Y 
  jal   get_index
  move  $t2, $v0                      #index of current bot 

  mul   $t2, $t2, 16
  add   $t3, $t0, $t2
  lw    $t4, 4($t3)
  beq   $t4, 1, skip_harvest          #check if tile is owned by our bot


   sw    $t0, HARVEST_TILE
   sw    $a0, BOT_X
   add   $a1, $a0, 30
   jal   moveToX
   j     harvesting_cont


 move_next_tile_fn: 

  sub     $sp, $sp, 16
  sw      $ra, 0($sp)
  sw      $s0, 4($sp)
  sw      $s1, 8($sp)
  sw      $s2, 12($sp)  
  
  move    $s0, $a0

  lw      $a0, counter
  jal     move_checkerboard
  lw      $s1, counter 

  # beq   $a0, $0, harvest

  add     $s1, $s1, 1
  sw      $s1, counter

  lw      $ra, 0($sp)
  lw      $s0, 4($sp)
  lw      $s1, 8($sp)
  lw      $s2, 12($sp) 
  add     $sp, $sp, 16
  jr      $ra 

harvest_tile:
  #a0 =   max_growth_tile_loc

  sub     $sp, $sp, 24
  sw      $ra, 0($sp)
  sw      $s0, 4($sp)
  sw      $s1, 8($sp)
  sw      $s2, 12($sp)
  sw      $s3, 16($sp) 
  sw      $s4, 20($sp)

  # lw      $s1  max_growth_on
  # beq     $s2, 1, 

  move    $s0, $a0

  li      $s1, 16  
  srl     $s2, $s0, $s1       #gets the x tile 
    
  li      $s1, 0x0000FFFF
  and     $s3, $s0, $s1       #gets the y tile 

get_coordinates:
  li      $s1, 30
  li      $s4, 15
  mul     $s2, $s2, $s1
  add     $s2, $s2, $s4       #gets the x coordinate
  mul     $s3, $s3, $s1 
  add     $s3, $s3, $s4       #gets the y coordinate

  lw      $a0, BOT_X($0)
  move    $a1, $s2
  jal     moveToX

  lw      $a0, BOT_Y($0)
  move    $a1, $s3 
  jal     moveToY

  sw      $0, HARVEST_TILE

  lw      $ra, 0($sp)
  lw      $s0, 4($sp)
  lw      $s1, 8($sp)
  lw      $s2, 12($sp)
  lw      $s3, 16($sp) 
  lw      $s4, 20($sp)
  add     $sp, $sp, 24

solve_puzzle:
  sub     $sp, $sp, 20
  sw      $ra, 0($sp)
  sw      $s0, 4($sp)
  sw      $s1, 8($sp)
  sw      $s2, 12($sp)
  sw      $s3, 16($sp)

  move    $s0, $a0
  move    $s1, $a1

	la 		$a0, solution_data
	la 		$a1, puzzle_data
	jal 	recursive_backtracking
	sw 		$a0, SUBMIT_SOLUTION

	sw 		$0, request_puzzle_on

  li    $s2, 0

  la    $s3, solution_data
clear_solution:
	bge 	$s2, 82, solve_puzzle_end
	sw 		$0, 0($s3)
	add 	$s3, $s3, 4
	add 	$s2, $s2, 1
	j 		clear_solution

solve_puzzle_end:
  lw      $ra, 0($sp)
  lw      $s0, 4($sp)
  lw      $s1, 8($sp)
  lw      $s2, 12($sp)
  lw      $s3, 16($sp)
  add     $sp, $sp, 20
  jr      $ra



request_and_solve:
  #$a0 is type of puzzle
  sub     $sp, $sp, 20
  sw      $ra, 0($sp)
  sw      $s0, 4($sp)
  sw      $s1, 8($sp)
  sw      $s2, 12($sp)
  sw      $s3, 16($sp) 

  move    $s0, $a0

  move    $s2, $s0
  sw      $s2, SET_RESOURCE_TYPE
  la      $s2, puzzle_data
  sw      $s2, REQUEST_PUZZLE

wait_for_ack:
  lw    $s3, request_puzzle_on
  beq   $s3, 0, wait_for_ack


  jal    solve_puzzle

  lw      $ra, 0($sp)
  lw      $s0, 4($sp)
  lw      $s1, 8($sp)
  lw      $s2, 12($sp)
  lw      $s3, 16($sp)
  add     $sp, $sp, 20
  jr      $ra

request_puzzle:
  #a0 = type of puzzle 
  sub     $sp, $sp, 12
  sw      $ra, 0($sp)
  sw      $s0, 4($sp)
  sw      $s1, 8($sp)

  move    $s0, $a0
  move    $s1, $s0
  sw      $s1, SET_RESOURCE_TYPE
  la      $s1, puzzle_data
  sw      $s1, REQUEST_PUZZLE

   
  lw      $ra, 0($sp)
  lw      $s0, 4($sp)
  lw      $s1, 8($sp)
  add     $sp, $sp, 12
  jr      $ra

move_checkerboard:
  #$a0 = counter(1-50)
  sub     $sp, $sp, 24
  sw      $ra, 0($sp)
  sw      $s0, 4($sp)
  sw      $s1, 8($sp)
  sw      $s2, 12($sp)
  sw      $s3, 16($sp)
  sw      $s4, 20($sp)

  move    $s0, $a0
  move    $s1, $a1

  bge     $s0, 50, reset_counter

  li      $s4, 5
  rem     $s4, $s0, $s4
  bne     $s4, 0, move_x
  # move in y direction
  
  lw      $s2, BOT_Y($0)
  sub     $a1, $s2, 30
  move    $a0, $s2
  jal     moveToY

move_x:
  li      $s3, 10
  rem     $s4, $s0, $s3       #counter / 10 
  beq     $s4, 0, move_left_30
  beq     $s4, 5, move_right_30
  bge     $s4, 6, move_left_60

move_right_60:
  lw      $s2, BOT_X
  add     $a1, $s2, 60
  move    $a0, $s2
  jal     moveToX
  j       end3

move_left_30:
  lw      $s2, BOT_X
  sub     $a1, $s2, 30
  move    $a0, $s2
  jal     moveToX
  j       end3

move_right_30:
  lw      $s2, BOT_X
  add     $a1, $s2, 30
  move    $a0, $s2
  jal     moveToX 
  j       end3

move_left_60:
  lw      $s2, BOT_X
  sub     $a1, $s2, 60
  move    $a0, $s2
  jal     moveToX
  j       end3

reset_counter:

  lw    $a0, BOT_X($0)
  li    $a1, 15 
  jal   moveToX

  lw    $a0, BOT_Y($0)
  li    $a1, 285
  jal   moveToY 

  sw    $0, counter

  li    $s3, 1 
  sw    $s3, harvesting

end3:

  lw      $ra, 0($sp)
  lw      $s0, 4($sp)
  lw      $s1, 8($sp)
  lw      $s2, 12($sp)
  lw      $s3, 16($sp)
  lw      $s4, 20($sp)
  add     $sp, $sp, 24
  jr      $ra

get_index:
  #$a0 = pixel_x
  #$a1 = pixel_y
  sub     $sp, $sp, 28
  sw      $ra, 0($sp)
  sw      $s0, 4($sp)
  sw      $s1, 8($sp)
  sw      $s2, 12($sp)
  sw      $s3, 16($sp)
  sw      $s4, 20($sp)
  sw      $s5, 24($sp)

  li      $s0, 15
  li      $s1, 30
  sub     $s2, $a0, $s0
  div     $s2, $s2, $s1   #tile_x
  sub     $s3, $a1, $s0
  div     $s3, $s3, $s1   #tile_y
  li      $s4, 10
  mul     $s5, $s3, $s4
  add     $s5, $s5, $s2

  move    $v0, $s5
  lw      $ra, 0($sp)
  lw      $s0, 4($sp)
  lw      $s1, 8($sp)
  lw      $s2, 12($sp)
  lw      $s3, 16($sp)
  lw      $s4, 20($sp)
  lw      $s5, 24($sp)
  add     $sp, $sp, 28

  jr      $ra 

moveToY:
    beq     $a0, $a1, end2
    blt     $a1, $a0, move_up 
    
move_down:
    li      $t0, 10
    li      $t1, 90
    li      $t4, 1
    sw      $t1, ANGLE($0)
    sw      $t4, ANGLE_CONTROL($0)
    sw      $t0, VELOCITY($0)
check_down:
    beq     $a0, $a1, end2
    lw      $a0, BOT_Y
    j       check_down


move_up:
    li      $t2, 10
    li      $t3, 270
    li      $t4, 1
    sw      $t3, ANGLE($0)
    sw      $t4, ANGLE_CONTROL($0)
    sw      $t2, VELOCITY($0)
check_up:
    beq     $a0, $a1, end2
    lw      $a0, BOT_Y
    j       check_up

end2:
    sw      $0, VELOCITY($0)
    jr      $ra 

moveToX:
    beq     $a0, $a1, end
    blt     $a1, $a0, move_left 

move_right:
    li      $t2, 10
    li      $t3, 0
    li      $t4, 1
    sw      $t3, ANGLE($0)
    sw      $t4, ANGLE_CONTROL($0)
    sw      $t2, VELOCITY($0)
check_right:
    beq     $a0, $a1, end
    lw      $a0, BOT_X 
    j       check_right
    
move_left:
    li      $t0, 10
    li      $t1, 180
    li      $t4, 1
    sw      $t1, ANGLE($0)
    sw      $t4, ANGLE_CONTROL($0)
    sw      $t0, VELOCITY($0)
check_left:
    beq     $a0, $a1, end
    lw      $a0, BOT_X
    j       check_left

end:
    sw      $0, VELOCITY($0)
    jr      $ra 

convert_highest_bit_to_int:
    move  $v0, $0           # result = 0

chbti_loop:
    beq   $a0, $0, chbti_end
    add   $v0, $v0, 1         # result ++
    sra   $a0, $a0, 1         # domain >>= 1
    j     chbti_loop

chbti_end:
    jr    $ra

get_domain_for_cell:
    # save registers    
    sub $sp, $sp, 36
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    sw $s3, 16($sp)
    sw $s4, 20($sp)
    sw $s5, 24($sp)
    sw $s6, 28($sp)
    sw $s7, 32($sp)

    li $t0, 0 # valid_domain
    lw $t1, 4($a1) # puzzle->grid (t1 free)
    sll $t2, $a0, 3 # position*8 (actual offset) (t2 free)
    add $t3, $t1, $t2 # &puzzle->grid[position]
    lw  $t4, 4($t3) # &puzzle->grid[position].cage
    lw  $t5, 0($t4) # puzzle->grid[posiition].cage->operation

    lw $t2, 4($t4) # puzzle->grid[position].cage->target

    move $s0, $t2   # remain_target = $s0  *!*!
    lw $s1, 8($t4) # remain_cell = $s1 = puzzle->grid[position].cage->num_cell
    lw $s2, 0($t3) # domain_union = $s2 = puzzle->grid[position].domain
    move $s3, $t4 # puzzle->grid[position].cage
    li $s4, 0   # i = 0
    move $s5, $t1 # $s5 = puzzle->grid
    move $s6, $a0 # $s6 = position
    # move $s7, $s2 # $s7 = puzzle->grid[position].domain

    bne $t5, 0, gdfc_check_else_if

    li $t1, 1
    sub $t2, $t2, $t1 # (puzzle->grid[position].cage->target-1)
    sll $v0, $t1, $t2 # valid_domain = 0x1 << (prev line comment)
    j gdfc_end # somewhere!!!!!!!!

gdfc_check_else_if:
    bne $t5, '+', gdfc_check_else

gdfc_else_if_loop:
    lw $t5, 8($s3) # puzzle->grid[position].cage->num_cell
    bge $s4, $t5, gdfc_for_end # branch if i >= puzzle->grid[position].cage->num_cell
    sll $t1, $s4, 2 # i*4
    lw $t6, 12($s3) # puzzle->grid[position].cage->positions
    add $t1, $t6, $t1 # &puzzle->grid[position].cage->positions[i]
    lw $t1, 0($t1) # pos = puzzle->grid[position].cage->positions[i]
    add $s4, $s4, 1 # i++

    sll $t2, $t1, 3 # pos * 8
    add $s7, $s5, $t2 # &puzzle->grid[pos]
    lw  $s7, 0($s7) # puzzle->grid[pos].domain

    beq $t1, $s6 gdfc_else_if_else # branch if pos == position

    

    move $a0, $s7 # $a0 = puzzle->grid[pos].domain
    jal is_single_value_domain
    bne $v0, 1 gdfc_else_if_else # branch if !is_single_value_domain()
    move $a0, $s7
    jal convert_highest_bit_to_int
    sub $s0, $s0, $v0 # remain_target -= convert_highest_bit_to_int
    addi $s1, $s1, -1 # remain_cell -= 1
    j gdfc_else_if_loop
gdfc_else_if_else:
    or $s2, $s2, $s7 # domain_union |= puzzle->grid[pos].domain
    j gdfc_else_if_loop

gdfc_for_end:
    move $a0, $s0
    move $a1, $s1
    move $a2, $s2
    jal get_domain_for_addition # $v0 = valid_domain = get_domain_for_addition()
    j gdfc_end

gdfc_check_else:
    lw $t3, 12($s3) # puzzle->grid[position].cage->positions
    lw $t0, 0($t3) # puzzle->grid[position].cage->positions[0]
    lw $t1, 4($t3) # puzzle->grid[position].cage->positions[1]
    xor $t0, $t0, $t1
    xor $t0, $t0, $s6 # other_pos = $t0 = $t0 ^ position
    lw $a0, 4($s3) # puzzle->grid[position].cage->target

    sll $t2, $s6, 3 # position * 8
    add $a1, $s5, $t2 # &puzzle->grid[position]
    lw  $a1, 0($a1) # puzzle->grid[position].domain
    # move $a1, $s7 

    sll $t1, $t0, 3 # other_pos*8 (actual offset)
    add $t3, $s5, $t1 # &puzzle->grid[other_pos]
    lw $a2, 0($t3)  # puzzle->grid[other_pos].domian

    jal get_domain_for_subtraction # $v0 = valid_domain = get_domain_for_subtraction()
    # j gdfc_end
gdfc_end:
# restore registers
    
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    lw $s3, 16($sp)
    lw $s4, 20($sp)
    lw $s5, 24($sp)
    lw $s6, 28($sp)
    lw $s7, 32($sp)
    add $sp, $sp, 36    
    jr $ra

 get_domain_for_addition:
    sub    $sp, $sp, 20
    sw     $ra, 0($sp)
    sw     $s0, 4($sp)
    sw     $s1, 8($sp)
    sw     $s2, 12($sp)
    sw     $s3, 16($sp)
    move   $s0, $a0                     # s0 = target
    move   $s1, $a1                     # s1 = num_cell
    move   $s2, $a2                     # s2 = domain

    move   $a0, $a2
    jal    convert_highest_bit_to_int
    move   $s3, $v0                     # s3 = upper_bound

    sub    $a0, $0, $s2                 # -domain
    and    $a0, $a0, $s2                # domain & (-domain)
    jal    convert_highest_bit_to_int   # v0 = lower_bound
     
    sub    $t0, $s1, 1                  # num_cell - 1
    mul    $t0, $t0, $v0                # (num_cell - 1) * lower_bound
    sub    $t0, $s0, $t0                # t0 = high_bits
    bge    $t0, 0, gdfa_skip0

    li     $t0, 0

gdfa_skip0:
    bge    $t0, $s3, gdfa_skip1

    li     $t1, 1          
    sll    $t0, $t1, $t0                # 1 << high_bits
    sub    $t0, $t0, 1                  # (1 << high_bits) - 1
    and    $s2, $s2, $t0                # domain & ((1 << high_bits) - 1)

gdfa_skip1:    
    sub    $t0, $s1, 1                  # num_cell - 1
    mul    $t0, $t0, $s3                # (num_cell - 1) * upper_bound
    sub    $t0, $s0, $t0                # t0 = low_bits
    ble    $t0, $0, gdfa_skip2

    sub    $t0, $t0, 1                  # low_bits - 1
    sra    $s2, $s2, $t0                # domain >> (low_bits - 1)
    sll    $s2, $s2, $t0                # domain >> (low_bits - 1) << (low_bits - 1)

gdfa_skip2:    
    move   $v0, $s2                     # return domain
    lw     $ra, 0($sp)
    lw     $s0, 4($sp)
    lw     $s1, 8($sp)
    lw     $s2, 12($sp)
    lw     $s3, 16($sp)
    add    $sp, $sp, 20
    jr     $ra

get_domain_for_subtraction:
    li     $t0, 1              
    li     $t1, 2
    mul    $t1, $t1, $a0            # target * 2
    sll    $t1, $t0, $t1            # 1 << (target * 2)
    or     $t0, $t0, $t1            # t0 = base_mask
    li     $t1, 0                   # t1 = mask

gdfs_loop:
    beq    $a2, $0, gdfs_loop_end 
    and    $t2, $a2, 1              # other_domain & 1
    beq    $t2, $0, gdfs_if_end
     
    sra    $t2, $t0, $a0            # base_mask >> target
    or     $t1, $t1, $t2            # mask |= (base_mask >> target)

gdfs_if_end:
    sll    $t0, $t0, 1              # base_mask <<= 1
    sra    $a2, $a2, 1              # other_domain >>= 1
    j      gdfs_loop

gdfs_loop_end:
    and    $v0, $a1, $t1            # domain & mask
    jr     $ra

is_single_value_domain:
    beq    $a0, $0, isvd_zero     # return 0 if domain == 0
    sub    $t0, $a0, 1            # (domain - 1)
    and    $t0, $t0, $a0          # (domain & (domain - 1))
    bne    $t0, $0, isvd_zero     # return 0 if (domain & (domain - 1)) != 0
    li     $v0, 1
    jr     $ra

isvd_zero:     
    li     $v0, 0
    jr     $ra
forward_checking:
  sub   $sp, $sp, 24
  sw    $ra, 0($sp)
  sw    $a0, 4($sp)
  sw    $a1, 8($sp)
  sw    $s0, 12($sp)
  sw    $s1, 16($sp)
  sw    $s2, 20($sp)
  lw    $t0, 0($a1)     # size
  li    $t1, 0          # col = 0
fc_for_col:
  bge   $t1, $t0, fc_end_for_col  # col < size
  div   $a0, $t0
  mfhi  $t2             # position % size
  mflo  $t3             # position / size
  beq   $t1, $t2, fc_for_col_continue    # if (col != position % size)
  mul   $t4, $t3, $t0
  add   $t4, $t4, $t1   # position / size * size + col
  mul   $t4, $t4, 8
  lw    $t5, 4($a1) # puzzle->grid
  add   $t4, $t4, $t5   # &puzzle->grid[position / size * size + col].domain
  mul   $t2, $a0, 8   # position * 8
  add   $t2, $t5, $t2 # puzzle->grid[position]
  lw    $t2, 0($t2) # puzzle -> grid[position].domain
  not   $t2, $t2        # ~puzzle->grid[position].domain
  lw    $t3, 0($t4) #
  and   $t3, $t3, $t2
  sw    $t3, 0($t4)
  beq   $t3, $0, fc_return_zero # if (!puzzle->grid[position / size * size + col].domain)
fc_for_col_continue:
  add   $t1, $t1, 1     # col++
  j     fc_for_col
fc_end_for_col:
  li    $t1, 0          # row = 0
fc_for_row:
  bge   $t1, $t0, fc_end_for_row  # row < size
  div   $a0, $t0
  mflo  $t2             # position / size
  mfhi  $t3             # position % size
  beq   $t1, $t2, fc_for_row_continue
  lw    $t2, 4($a1)     # puzzle->grid
  mul   $t4, $t1, $t0
  add   $t4, $t4, $t3
  mul   $t4, $t4, 8
  add   $t4, $t2, $t4   # &puzzle->grid[row * size + position % size]
  lw    $t6, 0($t4)
  mul   $t5, $a0, 8
  add   $t5, $t2, $t5
  lw    $t5, 0($t5)     # puzzle->grid[position].domain
  not   $t5, $t5
  and   $t5, $t6, $t5
  sw    $t5, 0($t4)
  beq   $t5, $0, fc_return_zero
fc_for_row_continue:
  add   $t1, $t1, 1     # row++
  j     fc_for_row
fc_end_for_row:

  li    $s0, 0          # i = 0
fc_for_i:
  lw    $t2, 4($a1)
  mul   $t3, $a0, 8
  add   $t2, $t2, $t3
  lw    $t2, 4($t2)     # &puzzle->grid[position].cage
  lw    $t3, 8($t2)     # puzzle->grid[position].cage->num_cell
  bge   $s0, $t3, fc_return_one
  lw    $t3, 12($t2)    # puzzle->grid[position].cage->positions
  mul   $s1, $s0, 4
  add   $t3, $t3, $s1
  lw    $t3, 0($t3)     # pos
  lw    $s1, 4($a1)
  mul   $s2, $t3, 8
  add   $s2, $s1, $s2   # &puzzle->grid[pos].domain
  lw    $s1, 0($s2)
  move  $a0, $t3
  jal get_domain_for_cell
  lw    $a0, 4($sp)
  lw    $a1, 8($sp)
  and   $s1, $s1, $v0
  sw    $s1, 0($s2)     # puzzle->grid[pos].domain &= get_domain_for_cell(pos, puzzle)
  beq   $s1, $0, fc_return_zero
fc_for_i_continue:
  add   $s0, $s0, 1     # i++
  j     fc_for_i
fc_return_one:
  li    $v0, 1
  j     fc_return
fc_return_zero:
  li    $v0, 0
fc_return:
  lw    $ra, 0($sp)
  lw    $a0, 4($sp)
  lw    $a1, 8($sp)
  lw    $s0, 12($sp)
  lw    $s1, 16($sp)
  lw    $s2, 20($sp)
  add   $sp, $sp, 24
  jr    $ra

get_unassigned_position:
  li    $v0, 0            # unassigned_pos = 0
  lw    $t0, 0($a1)       # puzzle->size
  mul  $t0, $t0, $t0     # puzzle->size * puzzle->size
  add   $t1, $a0, 4       # &solution->assignment[0]
get_unassigned_position_for_begin:
  bge   $v0, $t0, get_unassigned_position_return  # if (unassigned_pos < puzzle->size * puzzle->size)
  mul  $t2, $v0, 4
  add   $t2, $t1, $t2     # &solution->assignment[unassigned_pos]
  lw    $t2, 0($t2)       # solution->assignment[unassigned_pos]
  beq   $t2, 0, get_unassigned_position_return  # if (solution->assignment[unassigned_pos] == 0)
  add   $v0, $v0, 1       # unassigned_pos++
  j   get_unassigned_position_for_begin
get_unassigned_position_return:
  jr    $ra

is_complete:
  lw    $t0, 0($a0)       # solution->size
  lw    $t1, 0($a1)       # puzzle->size
  mul   $t1, $t1, $t1     # puzzle->size * puzzle->size
  move  $v0, $0
  seq   $v0, $t0, $t1
  j     $ra

recursive_backtracking:
  sub   $sp, $sp, 680
  sw    $ra, 0($sp)
  sw    $a0, 4($sp)     # solution
  sw    $a1, 8($sp)     # puzzle
  sw    $s0, 12($sp)    # position
  sw    $s1, 16($sp)    # val
  sw    $s2, 20($sp)    # 0x1 << (val - 1)
                        # sizeof(Puzzle) = 8
                        # sizeof(Cell [81]) = 648

  jal   is_complete
  bne   $v0, $0, recursive_backtracking_return_one
  lw    $a0, 4($sp)     # solution
  lw    $a1, 8($sp)     # puzzle
  jal   get_unassigned_position
  move  $s0, $v0        # position
  li    $s1, 1          # val = 1

recursive_backtracking_for_loop:
  lw    $a0, 4($sp)     # solution
  lw    $a1, 8($sp)     # puzzle
  lw    $t0, 0($a1)     # puzzle->size
  add   $t1, $t0, 1     # puzzle->size + 1
  bge   $s1, $t1, recursive_backtracking_return_zero  # val < puzzle->size + 1
  lw    $t1, 4($a1)     # puzzle->grid
  mul   $t4, $s0, 8     # sizeof(Cell) = 8
  add   $t1, $t1, $t4   # &puzzle->grid[position]
  lw    $t1, 0($t1)     # puzzle->grid[position].domain
  sub   $t4, $s1, 1     # val - 1
  li    $t5, 1
  sll   $s2, $t5, $t4   # 0x1 << (val - 1)
  and   $t1, $t1, $s2   # puzzle->grid[position].domain & (0x1 << (val - 1))
  beq   $t1, $0, recursive_backtracking_for_loop_continue # if (domain & (0x1 << (val - 1)))
  mul   $t0, $s0, 4     # position * 4
  add   $t0, $t0, $a0
  add   $t0, $t0, 4     # &solution->assignment[position]
  sw    $s1, 0($t0)     # solution->assignment[position] = val
  lw    $t0, 0($a0)     # solution->size
  add   $t0, $t0, 1
  sw    $t0, 0($a0)     # solution->size++
  add   $t0, $sp, 32    # &grid_copy
  sw    $t0, 28($sp)    # puzzle_copy.grid = grid_copy !!!
  move  $a0, $a1        # &puzzle
  add   $a1, $sp, 24    # &puzzle_copy
  jal   clone           # clone(puzzle, &puzzle_copy)
  mul   $t0, $s0, 8     # !!! grid size 8
  lw    $t1, 28($sp)
  
  add   $t1, $t1, $t0   # &puzzle_copy.grid[position]
  sw    $s2, 0($t1)     # puzzle_copy.grid[position].domain = 0x1 << (val - 1);
  move  $a0, $s0
  add   $a1, $sp, 24
  jal   forward_checking  # forward_checking(position, &puzzle_copy)
  beq   $v0, $0, recursive_backtracking_skip

  lw    $a0, 4($sp)     # solution
  add   $a1, $sp, 24    # &puzzle_copy
  jal   recursive_backtracking
  beq   $v0, $0, recursive_backtracking_skip
  j     recursive_backtracking_return_one # if (recursive_backtracking(solution, &puzzle_copy))
recursive_backtracking_skip:
  lw    $a0, 4($sp)     # solution
  mul   $t0, $s0, 4
  add   $t1, $a0, 4
  add   $t1, $t1, $t0
  sw    $0, 0($t1)      # solution->assignment[position] = 0
  lw    $t0, 0($a0)
  sub   $t0, $t0, 1
  sw    $t0, 0($a0)     # solution->size -= 1
recursive_backtracking_for_loop_continue:
  add   $s1, $s1, 1     # val++
  j     recursive_backtracking_for_loop
recursive_backtracking_return_zero:
  li    $v0, 0
  j     recursive_backtracking_return
recursive_backtracking_return_one:
  li    $v0, 1
recursive_backtracking_return:
  lw    $ra, 0($sp)
  lw    $a0, 4($sp)
  lw    $a1, 8($sp)
  lw    $s0, 12($sp)
  lw    $s1, 16($sp)
  lw    $s2, 20($sp)
  add   $sp, $sp, 680
  jr    $ra

 clone:
    lw  $t0, 0($a0)
    sw  $t0, 0($a1)

    mul $t0, $t0, $t0
    mul $t0, $t0, 2 # two words in one grid

    lw  $t1, 4($a0) # &puzzle(ori).grid
    lw  $t2, 4($a1) # &puzzle(clone).grid

    li  $t3, 0 # i = 0;
clone_for_loop:
    bge  $t3, $t0, clone_for_loop_end
    sll  $t4, $t3, 2 # i * 4
    add  $t5, $t1, $t4 # puzzle(ori).grid ith word
    lw   $t6, 0($t5)

    add  $t5, $t2, $t4 # puzzle(clone).grid ith word
    sw   $t6, 0($t5)
    
    addi $t3, $t3, 1 # i++
    
    j    clone_for_loop
clone_for_loop_end:

    jr  $ra


.kdata 
chunkIH: .space 8
non_intrpt_str: .asciiz "Non-interrupt exception\n"
unhandled_str:  .asciiz "Unhandled interrupt type\n"
.ktext 0x80000180

interrupt_handler:
.set noat
	move	$k1, $at		# Save $at                               
.set at
	la	$k0, chunkIH
	sw	$a0, 0($k0)		# Get some free registers                  
	sw	$a1, 4($k0)		# by storing them to a global variable     


	mfc0	$k0, $13		# Get Cause register                       
	srl	$a0, $k0, 2                
	and	$a0, $a0, 0xf		# ExcCode field                            
	bne	$a0, 0, non_intrpt         

interrupt_dispatch:			# Interrupt:                             
	mfc0	$k0, $13		# Get Cause register, again                 
	beq	$k0, 0, done		# handled all outstanding interrupts     

	and	$a0, $k0, BONK_MASK	# is there a bonk interrupt?                
	bne	$a0, 0, bonk_interrupt   

	and	$a0, $k0, TIMER_MASK	# is there a timer interrupt?
	bne	$a0, 0, timer_interrupt
 
    # and $a0, $k0, ON_FIRE_MASK
    # bne $a0, 0, on_fire_interrupt

    and $a0, $k0, REQUEST_PUZZLE_INT_MASK
    bne $a0, 0, request_puzzle_interrupt

    and $a0, $k0, MAX_GROWTH_INT_MASK
    bne $a0, 0, max_growth_interrupt
	# add dispatch for other interrupt types here.
	# note that we infinite loop to avoid stopping the simulation early

	li	$v0, PRINT_STRING	# Unhandled interrupt types
	la	$a0, unhandled_str
	syscall 
	j	done

bonk_interrupt:
	sw	$a1, BONK_ACK		# acknowledge interrupt
 
 	sw	$0, VELOCITY		# ???

	j	interrupt_dispatch	# see if other interrupts are waiting

timer_interrupt:
	sw	$a1, TIMER_ACK		# acknowledge interrupt

	li	$t0, 90			# ???
	sw	$t0, ANGLE		# ???
	sw	$zero, ANGLE_CONTROL	# ???

	lw	$v0, TIMER		# current time
	add	$v0, $v0, 50000  
	sw	$v0, TIMER		# request timer in 50000 cycles

	j	interrupt_dispatch	# see if other interrupts are waiting

non_intrpt:				# was some non-interrupt
	li	$v0, PRINT_STRING
	la	$a0, non_intrpt_str
	syscall				# print out an error message
	# fall through to done

done:
	la	$k0, chunkIH
	lw	$a0, 0($k0)		# Restore saved registers
	lw	$a1, 4($k0)
.set noat
	move	$at, $k1		# Restore $at
.set at 
	eret

# on_fire_interrupt:
#     sw    $a1, ON_FIRE_ACK
#     lw    $t0, GET_FIRE_LOC
#     sw    $t0, coordinates 
   # li    $t1, 1 
   # lw    $t1, co
   # li  $t0, 10
   # sw  $t0, VELOCITY
   # j      interrupt_dispatch
    
request_puzzle_interrupt:
	sw 	$a1, REQUEST_PUZZLE_ACK
	li 	$t2, 1
	sw 	$t2, request_puzzle_on
  
  j   interrupt_dispatch

max_growth_interrupt:
	sw   $a1, MAX_GROWTH_ACK
  li   $t2, 1
  sw   $t2, max_growth_on 
  lw   $t3, MAX_GROWTH_TILE
  sw   $t3, max_growth_loc

  j interrupt_dispatch



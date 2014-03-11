###
# this block is shared between client and server
###

@Cells = new Meteor.Collection 'cells' # define the data store

gameSummary = -> # create nice-to-handle object out of data

  winningCombos = [ # patterns for winning line-ups
    ['0','1','2']
    ['3','4','5']
    ['6','7','8']
    ['0','3','6']
    ['1','4','7']
    ['2','5','8']
    ['0','4','8']
    ['2','4','6']
  ]

  pickedCells = {} # which cells have been selected?
  for cell in Cells.find().fetch() # let's check the datbaase
    if cell.type? # oh, it's been picked (type is 'X' or 'O')
      pickedCells[cell.type]?= []
      pickedCells[cell.type].push cell._id # create a nice ovject of {x:[],y:[]}
  
  winners = {} # now let's calculate if the cells are winning cells
  for key, val of pickedCells # for x, y
    for combo in winningCombos # go through the combos
      pickedWinningCombo = _.all combo, (comboItem) -> # if the user has a combo match
        _.contains pickedCells[key], comboItem # that contains their picked cells
      if pickedWinningCombo # make them a winner
        winners[key] = true
        winners.winningCells = combo # and attach their combo
  
  return winners # if we have a winner we end up with something like {x:true, combo:[1,2,3]}

###
# client only block -- should be in a 'client' folder
###

if Meteor.isClient # only run on client

  # who's turn is it? if modulo (%) of picked cells 2 is 0, then it's X, otherwise, O
  currentPlayer = -> if (Cells.find({type:{$exists:true}}, {sort:{_id:1}}).count()%2) is 0 then 'X' else 'O'
  
  getWinner = -> # let's loop through the gameSummar object and check if we have a winner
    for key, val of gameSummary()
      if val is true 
        return key
    return false

  # reactive elements in 'board' template
  Template.board.helpers
    currentPlayer : -> currentPlayer() # as above
    winner : -> getWinner() # the winner (if she exists)
    # get all the cells
    cells : -> Cells.find {}, {sort:{_id:1}}
    # make the cells go green if they're winning cells
    buttonType : -> if @winning then 'btn-success' else if @type? then 'btn-primary' else 'btn-default'

  # event hooks
  Template.board.events
    'click .restart-game': -> Meteor.call 'restartGame'    
    'click .cell': ->
      # unless the cell is already picked, or it's game over
      unless Cells.findOne({_id:@_id})?.type? or getWinner()
        # update the cells collection so the cell has the player's type
        Cells.update {_id:@_id}, {$set: {type:currentPlayer()}}
        # if there are winning cells, let the server know
        # IRL, probably should be done server-side on all inserts
        if gameSummary().winningCells? then Meteor.call 'updateWinningCells'

###
# server only block -- should be in a a 'server' folder
###

if Meteor.isServer

  # server-side methods accessed by Meteor.call on the client
  Meteor.methods
    # reset state of all cells
    'restartGame' : -> Cells.update {}, {$unset:{type:true,winning:true}}, {multi:true}
    # if there's a winner, mark the cells green
    'updateWinningCells' : -> 
      if gameSummary().winningCells? 
        Cells.update {_id:{$in:gameSummary().winningCells}}, {$set: {winning:true}}, {multi:true}
  

  # populate cells collection if it doesn't already exist
  Meteor.startup ->
    if Cells.find().count() is 0
      for i in [0..8]
        Cells.insert {_id: "#{i}"}



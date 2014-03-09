###
# this block is shared between client and server
###

@Cells = new Meteor.Collection 'cells'

gameSummary = ->

  winningCombos = [
    ['0','1','2']
    ['3','4','5']
    ['6','7','8']
    ['0','3','6']
    ['1','4','7']
    ['2','5','8']
    ['0','4','8']
    ['2','4','6']
  ]

  pickedCells = {}
  for cell in Cells.find().fetch()
    if cell.type?
      pickedCells[cell.type]?= []
      pickedCells[cell.type].push cell._id
  
  winners = {}
  for key, val of pickedCells
    for combo in winningCombos
      pickedWinningCombo = _.all combo, (comboItem) -> 
        _.contains pickedCells[key], comboItem
      if pickedWinningCombo
        winners[key] = true
        winners.winningCells = combo
  
  return winners


###
# client only block -- should be in a 'client' folder
###

if Meteor.isClient

  currentPlayer = -> if (Cells.find({type:{$exists:true}}, {sort:{_id:1}}).count()%2) is 0 then 'X' else 'O'
  
  getWinner = ->
    for key, val of gameSummary()
      if val is true 
        return key
    return false

  # reactive elements in 'board' template
  Template.board.helpers
    currentPlayer : -> currentPlayer()
    winner : -> getWinner()
    cells : -> Cells.find {}, {sort:{_id:1}}
    buttonType : -> if @winning then 'btn-success' else if @type? then 'btn-primary' else 'btn-default'

  # event hooks
  Template.board.events
    'click .restart-game': -> Meteor.call 'restartGame'    
    'click .cell': ->
      unless Cells.findOne({_id:@_id})?.type? or getWinner()
        Cells.update {_id:@_id}, {$set: {type:currentPlayer()}}
        if gameSummary().winningCells? then Meteor.call 'updateWinningCells'

###
# server only block -- should be in a a 'server' folder
###

if Meteor.isServer

  # server-side methods accessed by Meteor.call on the client
  Meteor.methods
    'restartGame' : -> Cells.update {}, {$unset:{type:true,winning:true}}, {multi:true}
    'updateWinningCells' : -> 
      if gameSummary().winningCells? 
        Cells.update {_id:{$in:gameSummary().winningCells}}, {$set: {winning:true}}, {multi:true}
  

  # populate cells collection if it doesn't already exist
  Meteor.startup ->
    if Cells.find().count() is 0
      for i in [0..8]
        Cells.insert {_id: "#{i}"}



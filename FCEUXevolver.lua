--Welcome to FCEUXevolver! This is a simple neuro-evolution AI script that runs on the NES emulator FCEUX. 
--To use this program as intended, simply change the configurations and functions to suit the game you are playing(There will be more information on that later).
--After that, fire up FCEUX with nothing loaded, and run this code from the FCEUX lua script window which can be found in File > Lua > New Lua Script Window.

--What it does: It loads a ROM, plays a movie until it ends, and saves a state. Then it evolves to maximize the utility function without dying. If the highest score ever reached plateus, it saves a state at the end of the best attempt it ever did, and trains starting from that point all over again, and records a new movie of the whold thing.



---------------------------------------Some configurations you have to know(The ones set below are just examples, feel free to change it.)-----------------------------
screenX = 12 --What should be the horizontal resolution of the downscaled screen the AIs are going to see?
screenY = 12 --What should be the vertical resolution of the downscaled screen the AIs are going to see?
ROMlocation = "" --Which ROM should it load and play?
primaryMovieLocation = "" --What movie should it play first?(This movie is typically used to get past the title screen, or to start the AI in a specific part or the game.)
secondaryMovieLocation = "" --What filename should the final movie have?(This will be the movie this code will generate at the end. Basically, it will be the original movie with the AI inputs added at the end.)
randomness = 0.2 --How much should the values of the AI deviate each generation?
mortality = 5 --What ratio of attempts should persist to the next generation?(1: all of 'em 2: half 3: one third, and so on.)
timestep = 6000 --for how many frames should the attempt last?
totaltimesteps = 100 --How many times should it continue the game from the best game it played so far?
triesPerEpisode = 50 --How many attempts should it try per generation?
plateu = 50 --How many generations should it try before deciding that it has played the best possible game and continuing from it?
NeuralNetStructure = {} --What should the hidden layer of the AI's neural network look like?
HowManyInputs = 4 --How many buttons should the AI be able to press? Exactly which buttons it is allowed to press can be changed on line 203.
main = savestate.object(5) --These two are savestates it's going to use. The numbers don't matter, but make sure it doesn't overwrite any savestate you personally need!
buffer = savestate.object(6)
speed = "turbo" --At what speed should the emulator run?("normal", "turbo", "maximum")



--------------------------------------------------------------funtions you have to define properly depending on the game-------------------------------------------------
function utility() --This is the literal utility function, meant to give a score on how well the AI did. It could be a score, where it is on the screen, etc. The goal of the AI is to maximize it.
  return 0 --Obvously change this depending on the kind of game you are trying to AI.
end
function dead() --This is a function that is supposed to detect whether the player has died and should restart.
  return false --Again, change this depending on the game you're AIing. It should output "true" when the player is dead, and "false" when it isn't.
end --Note: By default, the code tries its best not to die and doesn't take any apptempts in which it died into consideration when choosing the best attempt. If you don't want this, you would have to tweak the code(Just make the function output "false" all the time).
--


--------------------------------This code will take care of the rest unless you want to mess with it. Please try to improve this if you are good at coding :(--------------------------------
function average(list)
  local a = 0
  for x = 1,#list do
    a = a + list[x]
  end
  return a / #list
end
function sigmoid(x)
  return 1 / (1 + (2.71828 ^ (-x)))
end
function leakrelu(x)
  if x < 0 then
    return x / 20
  else
    return x
  end
end
function biggest(list)
  local big = {1}
  for x = 2, #list do
    if list[x] > list[big[1]] then
      big = {x}
    elseif list[x] == list[big[1]] and big[1] ~= x then
      table.insert(big,x)
    end
  end
  return big[math.random(1,#big)]
end
function smallest(list)
  local big = {1}
  for x = 2, #list do
    if list[x] < list[big[1]] then
      big = {x}
    elseif list[x] == list[big[1]] and big[1] ~= x then
      table.insert(big,x)
    end
  end
  return big[math.random(1,#big)]
end
function activation(x)
  return sigmoid(x)
end
function init()
  nodes = {{}}
  weights = {}
  biases = {}
  for x = 1, NetDimensions[1] do
    table.insert(nodes[1],0)
  end
  for x = 2, #NetDimensions do
    table.insert(weights,{})
    table.insert(biases,{})
    table.insert(nodes,{})
    for y = 1,NetDimensions[x] do
      table.insert(weights[x - 1],{})
      table.insert(biases[x - 1],(2 * (math.random() - 0.5)) ^ 3)
      table.insert(nodes[x],0)
      for z = 1,NetDimensions[x - 1] do
        table.insert(weights[x - 1][y],(2 * (math.random() - 0.5)) ^ 3)
      end
    end
  end
end
function predict(input)
  local a = 0
  nodes[1] = input
  for x = 1,#weights do
    for y = 1,#weights[x] do
      a = biases[x][y]
      for z = 1,#weights[x][y] do
        a = a + nodes[x][z] * weights[x][y][z]
      end
      a = activation(a)
      nodes[x + 1][y] = a
    end
  end
end
function getscreen(screenX, screenY)
  local screen = {}
  local value = 0
  local r = 0
  local g = 0
  local b = 0
  local pallete = 0
  for x = 0, screenX - 1 do
    for y = 0, screenY - 1 do
      gui.pixel(x * math.floor(255 / screenX), y * math.floor(239 / screenY), "cyan") --The code puts markers on the screen as a debugging feature, but you can remove it by commenting out this line.
      value = 0
      for z = 0, math.floor(255 / screenX) - 1 do
        for w = 0, math.floor(239 / screenY) - 1 do
          r, g, b, pallete = emu.getscreenpixel(x * math.floor(255 / screenX) + z,y * math.floor(239 / screenY) + w, true)
          value = value + r + g + b
        end
      end
      table.insert(screen, value / math.floor((256 * 240) / (screenX * screenY)))
    end
  end
  return screen
end
weights = {}
biases = {}
nodes = {{}}
NetDimensions = {screenX * screenY}
for x = 1, #NeuralNetStructure do
  table.insert(NetDimensions, NeuralNetStructure[x])
end
table.insert(NetDimensions, HowManyInputs)



----------Load ROM, play movie until finished, save state----------
dummyarray = {}
emu.loadrom(ROMlocation)
emu.speedmode("maximum")
movie.play(primaryMovieLocation, true)
while movie.mode() ~= "finished" do
  emu.frameadvance()
  table.insert(dummyarray, joypad.get(1))
  end
movie.stop()
movie.record(secondaryMovieLocation)
movie.rerecordcounting(true)
for x = 1, #dummyarray do
  joypad.set(1, dummyarray[x])
  emu.frameadvance()
end
savestate.save(main)
emu.speedmode(speed)



-----------------------------The actual AI code(Warning: spaghetti code)----------------------------
wlist = {}
blist = {}
for x = 1, triesPerEpisode do
  init()
  table.insert(wlist, weights)
  table.insert(blist, biases)
end
generation = 0
bestfitness = 0
backupfit = 0
stuck = 0
howmanytimesteps = 1
while howmanytimesteps <= totaltimesteps do
  generation = generation + 1
  fitness = {}
  for x = 1, triesPerEpisode do
    weights = wlist[x]
    biases = blist[x]
    count = 1
    while count < timestep and not dead() do
      count = count + 1
      predict(getscreen(screenX, screenY))
      prediction = nodes[#nodes]
      actualinput = {}
      for y = 1, #prediction do
        if prediction[y] < 0.5 then
          table.insert(actualinput, false)
        else
          table.insert(actualinput, true)
        end
      end
      joypad.set(1,{left=actualinput[1],right=actualinput[2],A=actualinput[3],B=actualinput[4]}) --This is the line that dictateds which buttons can be pressed. Change if you must. "actualinput" is the table this code uses to represent the inputs the AI would be pressing.
      emu.frameadvance()
      gui.text(5, 10, "Timestep: "..howmanytimesteps.." Generation: "..generation.." Player: "..x.." out of "..triesPerEpisode.."\nFitness: "..utility().." Best fitness ever: "..bestfitness.."\n"..timestep - count.." frames until reset") --This makes a HUD with some information, but if you don't need it, you can comment it out with no problems.
    end
    table.insert(fitness, utility())
    if utility() > bestfitness then
      if not dead() then
        savestate.save(buffer)
      end
      bestfitness = utility()
    end
    savestate.load(main)
  end
  champ = biggest(fitness)
  nextw = {}
  nextb = {}
  for x = 1, math.ceil(#wlist / mortality) do
    contender = biggest(fitness)
    table.insert(nextw, wlist[contender])
    table.insert(nextb, blist[contender])
    fitness[contender] = -(10^20)
  end
  origin = #nextw
  while #nextw < triesPerEpisode do
    table.insert(nextw, {})
    table.insert(nextb, {})
    for x = 1, #nextw[1] do
      table.insert(nextw[#nextw], {})
      table.insert(nextb[#nextb], {})
      for y = 1, #nextw[1][x] do
        temp = math.random(1, origin)
        table.insert(nextw[#nextw][x], {})
        table.insert(nextb[#nextb][x], (nextb[temp][x][y] + randomness * (2 * (math.random() - 0.5)) ^ 3))
        for z = 1, #nextw[1][x][y] do
          table.insert(nextw[#nextw][x][y], nextw[temp][x][y][z] + randomness * (2 * (math.random() - 0.5)) ^ 3)
        end
      end
    end
  end
  wlist = nextw
  blist = nextb
  print("Generation:"..generation.." Best fitness:"..bestfitness)
  if stuck > plateu then
    savestate.load(buffer)
    savestate.save(main)
    howmanytimesteps = howmanytimesteps + 1
    print("Moved to next timestep!")
    stuck = 0
  end
  if backupfit < bestfitness then
    stuck = 0
  else
    stuck = stuck + 1
  end
  backupfit = bestfitness
end
movie.stop()

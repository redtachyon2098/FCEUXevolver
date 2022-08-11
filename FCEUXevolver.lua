--Welcome to FCEUXevolver! This is a simple neuro-evolution AI script that runs on the NES emulator FCEUX.
--To use this program as intended, simply change the configurations and functions to suit the game you are playing(There will be more information on that later).
--After that, fire up FCEUX with nothing loaded, and run this code from the FCEUX lua script window which can be found in File > Lua > New Lua Script Window.

--What it does: It loads a ROM, plays a movie until it ends, and saves a state. Then it evolves to maximize the average utility function without dying.
--After the AI has evolved enough to be decent, you can press the "select" button on your controller to generate a movie with the best AI inputs added in.

--With this version of the code, you can modify the time limit the AI is given on the fly, potentially making the process much faster.

--The configurations of this code is an example, I found it to be good when playing Super Mario Bros.
---------------------------------------Some configurations you have to know(The ones set below are just examples, feel free to change it.)-----------------------------
screenX = 15 --What should be the horizontal resolution of the downscaled screen the AIs are going to see?
screenY = 15 --What should be the vertical resolution of the downscaled screen the AIs are going to see?
ROMlocation = "SuperMarioBros.nes" --Which ROM should it load and play?
primaryMovieLocation = "primary.fm2" --What movie should it play first?(This movie is typically used to get past the title screen, or to start the AI in a specific part or the game.)
secondaryMovieLocation = "secondary.fm2" --What filename should the final movie have?(This will be the movie this code will generate at the end. Basically, it will be the original movie with the AI inputs added at the end.)
randomness = 0.05 --How much should the values of the AI deviate each generation? (This evolutionary algorithm does asexual reproduction, I'll implement crossover later.)
mortality = 5 --What ratio of attempts should persist to the next generation?(1: all of 'em 2: half 3: one third, and so on.)
timestep = 60 --for how many frames should the attempt initially last?
triesPerEpisode = 20 --How many attempts should it try per generation?
NetDimensions = {screenX * screenY, 40, 4} --How many layers and nodes per layer should the neural network have?(Don't change the first entry in the table. Also, the very last entry should be the number of buttons it should be allowed to press. Exactly which buttons it can press can be changed later in the code(See line 195). By default it can press A, B, left, right.)
main = savestate.object(5) --This is a savestate it's going to use. The number doesn't matter, but make sure it doesn't overwrite any savestates you personally need!
speed = "maximum" --At what speed should the emulator run?("normal", "turbo", "maximum")

--------------------------------------------------------------funtions you have to define properly depending on the game.-------------------------------------------------
function utility() --This is the literal utility function, meant to give a score on how well the AI did. It could be a score, where it is on the screen, etc. The goal of the AI is to maximize it.
  return memory.readbyte(109) * 256 + memory.readbyte(134) --Obviously change this depending on the kind of game you are trying to AI.
end
function dead() --This is a function that is supposed to detect whether the player has died and should restart.
  return memory.readbyte(1969) == 1 --Again, change this depending on the game you're AIing. It should output "true" when the player is dead, and "false" when it isn't.
end --Note: By default, the code tries its best not to die and immediately stops any attempts that die. If you don't want this, you would have to tweak the code(Just make the function output "false" all the time).
function timelimit(currentlimit, bestutility) --This is the function that updates the time limit based on the current time limit and the best score it got. Obviously change this depending on the game.
  if currentlimit > 3 * bestutility / 4 then
    return currentlimit
  else
    return math.floor(3 * bestutility / 4)
  end
end


--------------------------------This code will take care of the rest unless you want to mess with it. Please try to improve this if you are good at coding :(--------------------------------
function sigmoid(x)
  return 1 / (1 + (2.71828 ^ (-x)))
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
      gui.pixel(x * math.floor(255 / screenX), y * math.floor(239 / screenY), "cyan") --By the way, the code puts markers on the screen as a debugging feature, but you can remove it by commenting out this line.
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



----------Load ROM, play movie until finished, save state----------
dummyarray = {}
emu.loadrom(ROMlocation)
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
unproductive = 0
running = true
killswitch = false
while true do
  generation = generation + 1
  fitness = {}
  bestutility = 0
  for x = 1, triesPerEpisode do
    weights = wlist[x]
    biases = blist[x]
    count = 1
    totalscore = 0
    unproductive = 0
    prevut = 0
    while count < timestep and not dead() and unproductive < 180 do
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
      myinput = joypad.read(1)
      if myinput.select == true and running then     --The Terminate button.
        running = false
        print("Will terminate in next generation.")
      end
      joypad.set(1,{left=actualinput[1],right=actualinput[2],A=actualinput[3],B=actualinput[4], select=nil}) --This is the line that dictates which buttons can be pressed. Change if you must. "actualinput" is the table this code uses to represent the inputs the AI would be pressing.
      emu.frameadvance()
      gui.text(5, 10, " Generation: "..generation.." Player: "..x.." out of "..triesPerEpisode.."\nFitness: "..math.floor(totalscore / count).." Best fitness ever: "..math.floor(bestfitness).."\n"..timestep - count.." frames until reset") --This makes a HUD with some information, but if you don't need it, you can comment it out with no problems.
      totalscore = totalscore + utility()
      if utility() == prevut then
        unproductive = unproductive + 1
      else
        unproductive = 0
      end
      prevut = utility()
    end
    if not running and x == 1 then
      movie.stop()
      killswitch = true
      break
    end
    if bestutility < utility() then
      bestutility = utility()
    end
    totalscore = totalscore / count
    table.insert(fitness, totalscore)
    if totalscore > bestfitness then
      bestfitness = totalscore
    end
    savestate.load(main)
  end
  if killswitch then
    break
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
  if timestep < bestutility then
    timestep = timelimit(timestep, bestutility)
  end
end
emu.speedmode("normal")

# Peasant

## TODO

- [ ] Make a tools dependency chain: like we have a number of `pin` tools, each of it can have only one next level tool. This way we probably will be able to check low level resources availability: if `pin` is "taken" by any other tool then a new tool cannot be attached. `pin` can be taken by the SPI or I2C controller, and i2c\spi-device resources might also have its own chain.
- [ ] Search all modules inside of the Peasant.Tools namespace and run `introduce` on them to get module status. It is possible to make dependency chains and rerun a global introduction process after each tool attachment.



### Unsorted

#### A new tool attach
`attach(attrs)` ->
formal check with `record = new(attrs)` ->
if `%{valid?: true} = changeset` then `Toolbox.attach_tool(changeset)`


## New schema

### Abstractions

### Tool
- A tool Behavior description
- Local tool API
- The Tool namespace

##### State
- a tool structure and related cast\dump\load methods

#### Config
- an individual tool config struct

##### Action
- A tool action struct

##### Event
- A tool event struct

##### Handler
- GenServer and runtime handling
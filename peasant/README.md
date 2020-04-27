# Peasant

## TODO

- [ ] Make a tools dependency chain: like we have a number of `pin` tools, each of it can have only one next level tool. This way we probably will be able to check low level resources availability: if `pin` is "taken" by any other tool then a new tool cannot be attached. `pin` can be taken by the SPI or I2C controller, and i2c\spi-device resources might also have its own chain.
- [ ] Search all modules inside of the Peasant.Tools namespace and run `introduce` on them to get module status. It is possible to make dependency chains and rerun a global introduction process after each tool attachment.



### Unsorted

### Automation

#### State
- [X] uuid
- [X] name
- [X] description
- [X] steps
- [X] total_steps
- [X] last_step_index # default: -1
- [ ] last_step_started_at
- [X] active
- [X] new
- [X] timer

###### Steps
- [X] uuid
- [X] name
- [X] description
- [X] tool_uuid
- [X] action -> validate_action
- [ ] action_config -> cast action_config via action struct
- [ ] wait_for_events
- [X] active
- [ ] suspended_by_tool
- [X] type : "action" | "automation" | "awaiting"
- [X] time_to_wait - in ms
- [ ] automation_uuid for embedding automation


#### Methods
- [X] create -> Created
- [ ] delete -> Deleted
- [X] rename -> Renamed
- [ ] change_description -> DescriptionChanged
- [X] activate -> Activated
- [X] deactivate -> Deactivated

- [X] add_step_at -> StepAddedAt
- [X] delete_step -> StepDeletedAt
- [X] move_step_to -> StepMovedTo
- [X] rename_step -> StepRenamed
- [ ] change_step_description -> StepDescriptionChanged
- [X] activate_step -> StepActivated
- [X] deactivate_step -> StepDeactivated
- [ ] change_step_action -> StepActionChanged

#### Handler

#### ActivityMaster: DynamicSupervisor for Automations

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

Describe Actions via macros in Tool.Action module by `use/2` service `Tool.Action.Protocol` module and macro `action/2`:
```
action name, 
  config: [{field_name, field_type, [required: true | false, default: "", label: "", description: "", hint: ""]}],
  resulting_events: [Event1, Event2]
```

##### Event
- A tool event struct

##### Handler
- GenServer and runtime handling
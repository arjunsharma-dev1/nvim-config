return {
  {
    "stevearc/overseer.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function()
      require("overseer").setup()
    end,
    keys = function(_, keys)
      -- extend the existing <leader>m group
      return vim.list_extend(keys, {
        {
          "<leader>mR", -- capital R to avoid conflicts with LazyVim defaults
          function()
            local pickers = require("telescope.pickers")
            local finders = require("telescope.finders")
            local conf = require("telescope.config").values
            local actions = require("telescope.actions")
            local action_state = require("telescope.actions.state")
            local overseer = require("overseer")

            local function run_maven_with_class(main_class)
              local task = overseer.new_task({
                cmd = { "mvn" },
                args = { "compile", "exec:java", "-Dexec.mainClass=" .. main_class },
                cwd = vim.fn.getcwd(),
                components = {
                  "default",
                  { "open_output", direction = "dock", focus = true, on_start = "always" },
                },
              })
              task:start()
            end

            local function pick_main_class()
              local results = vim.fn.systemlist(
                "rg --no-heading --files-with-matches 'public static void main' src/main/java | sed 's|/|.|g; s|.java$||; s|^src.main.java.||'"
              )
              if vim.v.shell_error ~= 0 or #results == 0 then
                vim.notify("No Java main classes found", vim.log.levels.WARN)
                return
              end

              pickers
                .new({}, {
                  prompt_title = "Select Main Class",
                  finder = finders.new_table({ results = results }),
                  sorter = conf.generic_sorter({}),
                  attach_mappings = function(prompt_bufnr, map)
                    actions.select_default:replace(function()
                      actions.close(prompt_bufnr)
                      local selection = action_state.get_selected_entry()
                      if selection then
                        run_maven_with_class(selection[1])
                      end
                    end)
                    return true
                  end,
                })
                :find()
            end

            pick_main_class()
          end,
          desc = "Run Maven Project",
        },
      })
    end,
  },
}

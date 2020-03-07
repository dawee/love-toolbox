local hash = {}

function hash.deepcopy(orig)
  local orig_type = type(orig)
  local copy

  if orig_type == 'table' then
    copy = {}

    for orig_key, orig_value in next, orig, nil do
      copy[hash.deepcopy(orig_key)] = hash.deepcopy(orig_value)
    end

    setmetatable(copy, hash.deepcopy(getmetatable(orig)))
  else -- number, string, boolean, etc
    copy = orig
  end
  return copy
end

return hash
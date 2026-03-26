def apply_filters(df, filters):
    filtered = df.copy()
    for key, value in filters.items():
        if value is None:
            continue
        elif isinstance(value, tuple) and len(value) == 2:
            filtered = filtered[
                (filtered[key] >= value[0]) & (filtered[key] <= value[1])
            ]
        elif isinstance(value, list):
            filtered = filtered[filtered[key].isin(value)]
        else:
            filtered = filtered[filtered[key] == value]
    return filtered

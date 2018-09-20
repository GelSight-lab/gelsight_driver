function [direction] = trend(cur, len, fluc)
persistent mem
persistent cnt
disp(cnt);

if isempty(mem)
    mem = cur;
end

if isempty(cnt)
    cnt = 0;
end

if abs(cur - mem) > fluc
    cnt = cnt + sign(cur - mem);
    cnt = min(len, cnt);
    cnt = max(-len, cnt);
end

if cnt > len / 2
    direction = 1;
elseif cnt < -len / 2
    direction = -1;
else
    direction = 0;
end
mem = cur;

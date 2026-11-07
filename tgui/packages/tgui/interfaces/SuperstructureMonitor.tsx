import { useBackend } from 'tgui/backend';

import { Window } from '../layouts';

type Data = {
  hull: number;
  max_hull: number;
  shielding: number;
  max_shielding: number;
};

export const SuperstructureMonitor = (props) => {
  const { act, data } = useBackend<Data>();
  const { hull = 0, max_hull = 0, shielding = 0, max_shielding = 0 } = data;
  return (
    <Window width={300} height={300}>
      <Window.Content>
        H{hull}
        <br />
        MH
        {max_hull}
        <br />S{shielding}
        <br />
        MS
        {max_shielding}
        <br />
      </Window.Content>
    </Window>
  );
};
